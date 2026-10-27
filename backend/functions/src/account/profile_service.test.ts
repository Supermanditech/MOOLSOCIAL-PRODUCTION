import test from "node:test";
import assert from "node:assert/strict";
import { AccountProfileService, AccountProfileError,
  type AccountProfileRepository, type AccountProfileAccount,
  type AccountProfileCommit, type AccountProfileCommitResult,
  type AccountProfileReceipt, type AccountProfileActor,
  type DeliveryAddress, type InvoiceProfile } from "./profile_service.js";

// Isolated host fixture only: this is not a durable server repository or live
// account. Real transactional/connector acceptance is qualified separately.
const actor: AccountProfileActor = {uid:"account-a",projectId:"fixture-project"};
const stamp="2026-10-27T00:00:00.000Z";
const home: DeliveryAddress={id:"home",kind:"home",label:"Home",recipient:"Fixture recipient",
  phone:"9999999999",line:"Fixture address",area:"Jodhpur",pinCode:"342001",landmark:""};
const invoice: InvoiceProfile={id:"invoice-a",legalName:"Fixture business",gstin:"",
  billingAddress:"Fixture billing address",registration:"unregistered"};
const account=(uid=actor.uid): AccountProfileAccount=>({uid,status:"ACTIVE",profile:{
  ownerUid:uid,revision:0,updatedAt:stamp,displayName:"Original name",
  addresses:[structuredClone(home)],selectedAddressId:home.id,invoiceProfiles:[structuredClone(invoice)]}});
class FixtureStore implements AccountProfileRepository {
  accounts=new Map([[actor.uid,account()],["account-b",account("account-b")]]);
  receipts=new Map<string,AccountProfileReceipt>(); commits=0;
  throwBefore=false; throwAfter=false; recoveryUnavailable=false;
  commitResult: AccountProfileCommitResult|undefined;
  key(uid:string,id:string){return JSON.stringify([uid,id]);}
  async readAccount(uid:string){return structuredClone(this.accounts.get(uid));}
  async readReceipt(uid:string,id:string){
    if(this.recoveryUnavailable && this.commits>0)throw new Error("fixture transport failure");
    return structuredClone(this.receipts.get(this.key(uid,id)));
  }
  async commit(value:AccountProfileCommit):Promise<AccountProfileCommitResult>{
    this.commits++;
    if(this.commitResult)return this.commitResult;
    if(this.throwBefore)throw new Error("fixture unavailable before commit");
    const current=this.accounts.get(value.ownerUid);
    if(!current)return {state:"missing"};
    if(current.status!=="ACTIVE")return {state:"restricted"};
    const prior=this.receipts.get(this.key(value.ownerUid,value.requestId));
    if(prior)return {state:"replayed",receipt:structuredClone(prior)};
    if(!current.profile || current.profile.revision!==value.expectedRevision)return {state:"conflict"};
    const receipt={ownerUid:value.ownerUid,requestId:value.requestId,fingerprint:value.fingerprint,
      profile:structuredClone(value.profile)};
    this.accounts.set(value.ownerUid,{...current,profile:structuredClone(value.profile)});
    this.receipts.set(this.key(value.ownerUid,value.requestId),receipt);
    if(this.throwAfter)throw new Error("fixture lost response after commit");
    return {state:"applied",receipt:structuredClone(receipt)};
  }
}
function setup(){const store=new FixtureStore();return {store,
  service:new AccountProfileService(store,actor.projectId,()=>new Date(stamp))};}
test("B01 host: erased Profile never becomes an empty active account",async()=>{
 const {store,service}=setup();
 store.accounts.set(actor.uid,{uid:actor.uid,status:"DELETED",profile:null});
 await assert.rejects(service.read(actor),(e:unknown)=>
  e instanceof AccountProfileError&&e.code==="account_restricted"&&e.status===403);
 await assert.rejects(service.save(actor,{requestId:"erased-save",expectedRevision:0,
  change:{kind:"name",displayName:"New name"}}),(e:unknown)=>
  e instanceof AccountProfileError&&e.code==="account_restricted"&&e.status===403);
 assert.equal(store.commits,0);
});
const nameRequest=(id="request-one",expectedRevision=0,displayName="New name")=>({
  requestId:id,expectedRevision,change:{kind:"name",displayName}});
const rejects=(promise:Promise<unknown>,code:string)=>assert.rejects(promise,
  (e:unknown)=>e instanceof AccountProfileError&&e.code===code);

test("B01 host: owner read and returned-copy isolation",async()=>{
  const {store,service}=setup(); const result=await service.read(actor);
  assert.equal(result.ownerUid,actor.uid);
  (result.addresses as DeliveryAddress[]).splice(0);
  assert.equal((await service.read(actor)).addresses.length,1);
  assert.equal(store.commits,0);
});
for(const forged of [{...actor,projectId:"foreign"},{...actor,tenantId:"other-tenant"},
  {...actor,uid:""},{...actor,uid:"bad\nuid"}]){
  test(`B01 host: forged/missing principal refused ${JSON.stringify(forged)}`,async()=>{
    const {store,service}=setup(); await rejects(service.save(forged,nameRequest()),"account_scope_mismatch");
    assert.equal(store.commits,0);
  });
}
for(const status of ["RESTRICTED","DELETED"] as const){
 test(`B01 host: ${status} never reactivated by Profile`,async()=>{
  const {store,service}=setup(); store.accounts.set(actor.uid,{...account(),status});
  await rejects(service.read(actor),"account_restricted");
  await rejects(service.save(actor,nameRequest()),"account_restricted");
  assert.equal(store.accounts.get(actor.uid)?.status,status); assert.equal(store.commits,0);
 });
}
test("B01 host: unknown account is not fabricated or created",async()=>{
 const {store,service}=setup(); store.accounts.delete(actor.uid);
 await rejects(service.read(actor),"account_not_ready"); assert.equal(store.commits,0);
});
test("B01 host: Profile name save preserves delivery, invoice and account B",async()=>{
 const {store,service}=setup(); const before=structuredClone(store.accounts.get("account-b"));
 const result=await service.save(actor,nameRequest());
 assert.equal(result.profile.displayName,"New name"); assert.equal(result.profile.revision,1);
 assert.deepEqual(result.profile.addresses,[home]); assert.deepEqual(result.profile.invoiceProfiles,[invoice]);
 assert.deepEqual(store.accounts.get("account-b"),before);
});
test("B01 host: name whitespace is canonical; replay does not write twice",async()=>{
 const {store,service}=setup(); const original=await service.save(actor,nameRequest("same-key",0,"  New   name  "));
 const replay=await service.save(actor,nameRequest("same-key",0,"New name"));
 assert.deepEqual(replay,original); assert.equal(store.commits,1);
});
test("B01 host: changed payload under original request identity conflicts",async()=>{
 const {store,service}=setup(); await service.save(actor,nameRequest());
 await rejects(service.save(actor,nameRequest("request-one",0,"Changed name")),"profile_request_conflict");
 assert.equal(store.commits,1);
});
test("B01 host: stale update refused; original receipt survives a later update",async()=>{
 const {store,service}=setup(); const original=await service.save(actor,nameRequest());
 await service.save(actor,nameRequest("second-key",1,"Later name"));
 await rejects(service.save(actor,nameRequest("stale-key",0)),"profile_revision_conflict");
 assert.deepEqual(await service.reconcile(actor,{requestId:"request-one"}),original);
 assert.equal((await service.read(actor)).displayName,"Later name"); assert.equal(store.commits,2);
});
for(const bad of [null,[],{...nameRequest(),ownerUid:"account-b"},
 {...nameRequest(),change:{kind:"name",displayName:"a"}},
 {...nameRequest(),change:{kind:"name",displayName:"x".repeat(61)}},
 {...nameRequest(),change:{kind:"name",displayName:"name",status:"ACTIVE"}},
 {...nameRequest(),expectedRevision:-1},{...nameRequest(),expectedRevision:1.5},
 {...nameRequest(),change:{kind:"workspace",approved:true}}]){
 test(`B01 host: malformed or privilege-bearing request refused ${JSON.stringify(bad)}`,async()=>{
  const {store,service}=setup(); await rejects(service.save(actor,bad),"invalid_profile_request");
  assert.equal(store.commits,0);
 });
}
for(const kind of ["home","work","thirdParty","other"] as const){
 test(`B01 host: existing delivery kind ${kind} round-trips`,async()=>{
  const {service}=setup(); const value={...home,kind,landmark:"Near fixture landmark"};
  const result=await service.save(actor,{requestId:"delivery-key",expectedRevision:0,
    change:{kind:"delivery",addresses:[value],selectedAddressId:value.id}});
  assert.deepEqual(result.profile.addresses,[value]);
  assert.equal(result.profile.displayName,"Original name"); assert.deepEqual(result.profile.invoiceProfiles,[invoice]);
 });
}
test("B01 host: address removal clears only explicit selected field; original snapshot unchanged",async()=>{
 const {service}=setup(); const historical=structuredClone(home);
 const result=await service.save(actor,{requestId:"remove-key",expectedRevision:0,
   change:{kind:"delivery",addresses:[],selectedAddressId:null}});
 assert.deepEqual(result.profile.addresses,[]); assert.equal(result.profile.selectedAddressId,null);
 assert.deepEqual(historical,home); // Fixture proof only; real immutable order tests remain required.
});
for(const delta of [{addresses:[home,home],selectedAddressId:"home"},
 {addresses:[home],selectedAddressId:"missing"},{addresses:[{...home,pinCode:"000000"}],selectedAddressId:"home"},
 {addresses:[{...home,ownerUid:"account-b"}],selectedAddressId:"home"}]){
 test(`B01 host: invalid delivery selection/identity refused ${JSON.stringify(delta)}`,async()=>{
  const {store,service}=setup(); await rejects(service.save(actor,{requestId:"address-key",expectedRevision:0,
    change:{kind:"delivery",...delta}}),"invalid_profile_request"); assert.equal(store.commits,0);
 });
}
for(const registration of ["registered","unregistered"] as const){
 test(`B01 host: ${registration} invoice stays billing data only`,async()=>{
  const {service}=setup(); const value={...invoice,registration,gstin:registration==="registered"?"27ABCDE1234F1Z5":""};
  const result=await service.save(actor,{requestId:"invoice-key",expectedRevision:0,
    change:{kind:"invoices",invoiceProfiles:[value]}});
  assert.deepEqual(result.profile.invoiceProfiles,[value]); assert.deepEqual(result.profile.addresses,[home]);
  assert.equal("gstVerified" in result.profile.invoiceProfiles[0]!,false);
  assert.equal("workspaceApproved" in result.profile,false);
 });
}
test("B01 host: unregistered profile cannot silently retain GST registration",async()=>{
 const {store,service}=setup(); await rejects(service.save(actor,{requestId:"invoice-key",expectedRevision:0,
 change:{kind:"invoices",invoiceProfiles:[{...invoice,gstin:"27ABCDE1234F1Z5"}]}}),"invalid_profile_request");
 assert.equal(store.commits,0);
});
for(const mode of ["before","after","reconcile-unavailable"]){
 test(`B01 host: transport outcome ${mode} preserves original request`,async()=>{
  const {store,service}=setup(); store.throwBefore=mode!=="after"; store.throwAfter=mode==="after";
  store.recoveryUnavailable=mode==="reconcile-unavailable";
  if(mode==="after"){
    const receipt=await service.save(actor,nameRequest()); assert.equal(receipt.requestId,"request-one");
    assert.equal(receipt.profile.displayName,"New name");
  }else{
    await rejects(service.save(actor,nameRequest()),"profile_outcome_unknown");
    assert.equal(store.accounts.get(actor.uid)?.profile?.displayName,"Original name");
  }
  assert.equal(store.commits,1);
 });
}
test("B01 host: unrelated receipt cannot qualify reconciliation",async()=>{
 const {store,service}=setup(); const result=await service.save(actor,nameRequest());
 store.receipts.set(store.key(actor.uid,"request-one"),{...result,ownerUid:"account-b"});
 await rejects(service.reconcile(actor,{requestId:"request-one"}),"account_scope_mismatch");
});
test("B01 host: absent receipt stays absent, not successful",async()=>{
 const {store,service}=setup(); assert.equal(await service.reconcile(actor,{requestId:"unknown-key"}),null);
 assert.equal(store.commits,0);
});
test("B01 host: oversized payload rejected before repository mutation",async()=>{
 const {store,service}=setup(); await rejects(service.save(actor,nameRequest("large-key",0,"x".repeat(70000))),"profile_request_too_large");
 assert.equal(store.commits,0);
});
