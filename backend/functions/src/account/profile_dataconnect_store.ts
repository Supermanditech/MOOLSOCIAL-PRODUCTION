import type { DataConnect } from "firebase-admin/data-connect";
import { AccountProfileError, decodeStoredAccountProfile,
  type AccountProfileRepository, type AccountProfileAccount,
  type AccountProfileCommit, type AccountProfileCommitResult,
  type AccountProfileReceipt } from "./profile_service.js";

/** The existing AppUser is the sole account master. Values are parameters,
 * never SQL text. PostgreSQL rechecks this conditional UPDATE after row-lock
 * waits: same-key replay is a no-op; a different stale request cannot write.
 * Profile and its original receipt are changed by the same atomic statement. */
export const ACCOUNT_PROFILE_COMMIT_SQL = `
UPDATE app_user SET
  display_name = CASE WHEN COALESCE(profile_receipts_json, '{}')::jsonb ? $2::text
    THEN display_name ELSE $5::jsonb ->> 'displayName' END,
  profile_revision = CASE WHEN COALESCE(profile_receipts_json, '{}')::jsonb ? $2::text
    THEN profile_revision ELSE profile_revision + 1 END,
  profile_data_json = CASE WHEN COALESCE(profile_receipts_json, '{}')::jsonb ? $2::text
    THEN profile_data_json ELSE $5::text END,
  profile_receipts_json = CASE WHEN COALESCE(profile_receipts_json, '{}')::jsonb ? $2::text
    THEN profile_receipts_json ELSE
    (COALESCE(profile_receipts_json, '{}')::jsonb || jsonb_build_object($2::text, $6::jsonb))::text END,
  updated_at = CASE WHEN COALESCE(profile_receipts_json, '{}')::jsonb ? $2::text
    THEN updated_at ELSE ($5::jsonb ->> 'updatedAt')::timestamptz END
WHERE uid = $1 AND status = 'ACTIVE' AND (
  (COALESCE(profile_receipts_json, '{}')::jsonb ? $2::text AND
   COALESCE(profile_receipts_json, '{}')::jsonb -> $2::text ->> 'fingerprint' = $4)
  OR (NOT (COALESCE(profile_receipts_json, '{}')::jsonb ? $2::text)
      AND profile_revision = $3::integer))
RETURNING (profile_receipts_json::jsonb -> $2::text)::text AS receipt_json
`;
type Transport = Pick<DataConnect, "executeGraphql" | "executeGraphqlRead">;
interface Row {
  uid: string; status: "ACTIVE" | "RESTRICTED" | "DELETED";
  displayName: string | null; updatedAt: string; profileRevision: number;
  profileDataJson: string | null;
}
function unavailable(): never {throw new AccountProfileError("profile_record_unavailable",503);}
function parse(raw: string): unknown {try{return JSON.parse(raw) as unknown;}catch{return unavailable();}}
function receipt(raw: string, owner: string, key: string): AccountProfileReceipt {
  const v=parse(raw);
  if (!v || typeof v!=="object" || Array.isArray(v)) return unavailable();
  const r=v as Record<string,unknown>;
  if (Object.keys(r).sort().join("|")!=="fingerprint|ownerUid|profile|requestId" ||
    r.ownerUid!==owner || r.requestId!==key || typeof r.fingerprint!=="string" ||
    !/^[a-f0-9]{64}$/u.test(r.fingerprint) || !r.profile || typeof r.profile!=="object") return unavailable();
  const rev=(r.profile as Record<string,unknown>).revision;
  if (typeof rev!=="number")return unavailable();
  return {ownerUid:owner,requestId:key,fingerprint:r.fingerprint,
    profile:decodeStoredAccountProfile(r.profile,owner,rev)};
}
export class DataConnectAccountProfileRepository implements AccountProfileRepository {
  constructor(private readonly transport: Transport) {}
  async readAccount(ownerUid: string): Promise<AccountProfileAccount|undefined> {
    const result=await this.transport.executeGraphqlRead<{appUser?:Row|null},{uid:string}>(`
      query ReadOwnedAccountProfile($uid: String!) {
        appUser(key: {uid:$uid}) {uid status displayName updatedAt profileRevision profileDataJson}
      }`,{variables:{uid:ownerUid}});
    const row=result.data.appUser;
    if(!row)return undefined;
    if(row.uid!==ownerUid || !["ACTIVE","RESTRICTED","DELETED"].includes(row.status) ||
      !Number.isSafeInteger(row.profileRevision) || row.profileRevision<0) return unavailable();
    // An erased/restricted account is a status result, not an empty active
    // Profile. Do not decode retained or erased private fields for this state.
    if(row.status!=="ACTIVE")return {uid:ownerUid,status:row.status,profile:null};
    let profile;
    if(row.profileDataJson===null){
      if(row.profileRevision!==0 || !Number.isFinite(Date.parse(row.updatedAt)))return unavailable();
      // Empty address/invoice collections reflect absent server data, never an
      // automatic import of ownerless device fields or invented business data.
      profile=decodeStoredAccountProfile({ownerUid,revision:0,updatedAt:new Date(row.updatedAt).toISOString(),
        displayName:row.displayName,addresses:[],selectedAddressId:null,invoiceProfiles:[]},ownerUid,0);
    }else{
      if(typeof row.profileDataJson!=="string")return unavailable();
      profile=decodeStoredAccountProfile(parse(row.profileDataJson),ownerUid,row.profileRevision);
      if(profile.displayName!==row.displayName)return unavailable();
    }
    return {uid:ownerUid,status:row.status,profile};
  }
  async readReceipt(ownerUid:string,requestId:string):Promise<AccountProfileReceipt|undefined>{
    const result=await this.transport.executeGraphqlRead<{
      receipts:readonly {receipt_json:string|null}[]
    },{uid:string;requestId:string}>(`
      query ReadOriginalAccountProfileReceipt($uid:String!,$requestId:String!) {
        receipts:_executeQuery(sql:"""
          SELECT (profile_receipts_json::jsonb -> $2::text)::text AS receipt_json
          FROM app_user WHERE uid=$1 AND status='ACTIVE'
        """,params:[$uid,$requestId])
      }`,{variables:{uid:ownerUid,requestId}});
    const rows=result.data.receipts;
    if(!Array.isArray(rows) || rows.length>1)return unavailable();
    const raw=rows[0]?.receipt_json;
    if(raw===null || rows.length===0)return undefined;
    if(typeof raw!=="string")return unavailable();
    return receipt(raw,ownerUid,requestId);
  }
  async commit(change:AccountProfileCommit):Promise<AccountProfileCommitResult>{
    if(change.profile.ownerUid!==change.ownerUid || change.profile.revision!==change.expectedRevision+1 ||
      !Number.isSafeInteger(change.expectedRevision) || change.expectedRevision<0 ||
      change.profile.revision>2147483647 || !/^[a-f0-9]{64}$/u.test(change.fingerprint))return unavailable();
    const original:AccountProfileReceipt={ownerUid:change.ownerUid,requestId:change.requestId,
      fingerprint:change.fingerprint,profile:decodeStoredAccountProfile(change.profile,change.ownerUid,change.profile.revision)};
    const result=await this.transport.executeGraphql<{
      committed?:{receipt_json:string}|null
    },{uid:string;requestId:string;expectedRevision:number;fingerprint:string;profile:string;receipt:string}>(`
      mutation CommitOwnedAccountProfile($uid:String!,$requestId:String!,$expectedRevision:Int!,
        $fingerprint:String!,$profile:String!,$receipt:String!) {
        committed:_executeReturningFirst(sql:"""${ACCOUNT_PROFILE_COMMIT_SQL}""",
          params:[$uid,$requestId,$expectedRevision,$fingerprint,$profile,$receipt])
      }`,{variables:{uid:change.ownerUid,requestId:change.requestId,
        expectedRevision:change.expectedRevision,fingerprint:change.fingerprint,
        profile:JSON.stringify(original.profile),receipt:JSON.stringify(original)}});
    if(result.data.committed){
      const saved=receipt(result.data.committed.receipt_json,change.ownerUid,change.requestId);
      if(saved.fingerprint!==change.fingerprint)throw new AccountProfileError("profile_request_conflict",409);
      return {state:saved.profile.revision===change.profile.revision?"applied":"replayed",receipt:saved};
    }
    // Reconciliation is a new read snapshot: it also resolves a concurrent
    // identical request that committed while our UPDATE was waiting on a lock.
    const account=await this.readAccount(change.ownerUid);
    if(!account)return {state:"missing"};
    if(account.status!=="ACTIVE")return {state:"restricted"};
    const saved=await this.readReceipt(change.ownerUid,change.requestId);
    return saved?{state:"replayed",receipt:saved}:{state:"conflict"};
  }
}
