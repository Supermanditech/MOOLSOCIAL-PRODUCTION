import { SocialContentError } from "../social/contracts.js";
import { verifySocialInvocation, type VerifiedSocialAppCheck } from "../social/request_security.js";
import { AccountProfileError, type AccountProfileActor, type AccountProfileService } from "./profile_service.js";

export interface AccountProfileHttpDependencies {
  readonly projectId: string;
  /** True only after actual schema, erasure and deployment qualification.
   * False is unavailable, never an in-memory production substitute. */
  readonly storageQualified: boolean;
  verifyAppCheck(token:string,consume:boolean):Promise<VerifiedSocialAppCheck>;
  verifyIdToken(token:string):Promise<AccountProfileActor & {anonymous?:boolean}>;
  readonly service: AccountProfileService;
}
export interface AccountProfileHttpInput {
  readonly method: string;
  readonly headers: Readonly<Record<string,string|string[]|undefined>>;
  readonly body: unknown;
  readonly bodyBytes: number;
}
export interface AccountProfileHttpReply {
  readonly status: number;
  readonly body: {readonly ok:true; readonly data:unknown} |
    {readonly ok:false; readonly error:{readonly code:string;readonly message:string;readonly uncertain:boolean}};
}
function invalid():never{throw new AccountProfileError("invalid_profile_request",400);}
function message(code:string):string{
  switch(code){
    case "authentication_required":case "account_scope_mismatch":return "Sign in again to use your Profile.";
    case "permission_denied":return "App verification is required.";
    case "profile_revision_conflict":return "Your Profile changed. Review the latest details before saving.";
    case "profile_request_conflict":return "The original save needs checking. Review it before trying again.";
    case "profile_outcome_unknown":return "Save status is not confirmed. Check the original save.";
    case "account_restricted":return "Profile access is unavailable for this account.";
    case "account_not_ready":return "Your account setup is not ready yet.";
    case "profile_request_too_large":return "These Profile details are too large to save together.";
    case "invalid_profile_request":return "Check the Profile details and try again.";
    default:return "Profile is unavailable right now. Try again later.";
  }
}
export async function handleAccountProfileRequest(input:AccountProfileHttpInput,
  deps:AccountProfileHttpDependencies):Promise<AccountProfileHttpReply>{
  try{
    if(input.method!=="POST")throw new AccountProfileError("invalid_profile_request",405);
    if(!Number.isSafeInteger(input.bodyBytes)||input.bodyBytes<0||input.bodyBytes>65536){
      throw new AccountProfileError("profile_request_too_large",413);
    }
    if(!input.body||typeof input.body!=="object"||Array.isArray(input.body))invalid();
    const body=input.body as Record<string,unknown>;
    if(Object.keys(body).some(k=>k!=="operation"&&k!=="payload")||typeof body.operation!=="string"||
      !["read","save","reconcile"].includes(body.operation))invalid();
    const payload=body.payload;
    if(!payload||typeof payload!=="object"||Array.isArray(payload))invalid();
    if(body.operation==="read"&&Object.keys(payload).length!==0)invalid();
    let actor:AccountProfileActor|undefined;
    const uid=await verifySocialInvocation(input.headers,{
      verifyAppCheck:(token,consume)=>deps.verifyAppCheck(token,consume),
      verifyIdToken:async token=>{
        const principal=await deps.verifyIdToken(token);
        if(principal.anonymous||principal.projectId!==deps.projectId||principal.tenantId!==undefined){
          throw new AccountProfileError("account_scope_mismatch",403);
        }
        actor={uid:principal.uid,projectId:principal.projectId};
        return {uid:principal.uid};
      },
    },body.operation==="save",true);
    if(!uid||!actor||actor.uid!==uid)throw new AccountProfileError("authentication_required",401);
    if(!deps.storageQualified)throw new AccountProfileError("profile_service_unavailable",503);
    const data=body.operation==="read"?await deps.service.read(actor):
      body.operation==="save"?await deps.service.save(actor,payload):await deps.service.reconcile(actor,payload);
    return {status:200,body:{ok:true,data}};
  }catch(error){
    if(error instanceof AccountProfileError){
      return {status:error.status,body:{ok:false,error:{code:error.code,message:message(error.code),uncertain:error.uncertain}}};
    }
    if(error instanceof SocialContentError){
      return {status:error.httpStatus,body:{ok:false,error:{code:error.code,message:message(error.code),uncertain:false}}};
    }
    // Never reflect SDK/SQL exceptions or submitted private fields in a reply.
    return {status:503,body:{ok:false,error:{code:"profile_service_unavailable",message:message("profile_service_unavailable"),uncertain:false}}};
  }
}
