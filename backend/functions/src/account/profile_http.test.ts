import test from "node:test";
import assert from "node:assert/strict";
import {handleAccountProfileRequest,type AccountProfileHttpDependencies,type AccountProfileHttpInput} from "./profile_http.js";
import {AccountProfileError,AccountProfileService,type AccountProfileRepository,type AccountProfileAccount} from "./profile_service.js";
function setup(){
  let reads=0,commits=0;
  const proofs:boolean[]=[];
  const account:AccountProfileAccount={uid:"fixture-owner",status:"ACTIVE",profile:{
    ownerUid:"fixture-owner",revision:0,updatedAt:"2026-10-27T00:00:00.000Z",
    displayName:null,addresses:[],selectedAddressId:null,invoiceProfiles:[]}};
  const repository:AccountProfileRepository={
    async readAccount(){reads++;return structuredClone(account);},
    async readReceipt(){return undefined;},
    async commit(change){commits++;return {state:"applied",receipt:{ownerUid:change.ownerUid,
      requestId:change.requestId,fingerprint:change.fingerprint,profile:change.profile}};},
  };
  const deps:AccountProfileHttpDependencies={projectId:"fixture-project",storageQualified:true,
    async verifyAppCheck(token,consume){assert.equal(token,"fixture-proof");proofs.push(consume);return {};},
    async verifyIdToken(token){assert.equal(token,"fixture-identity");return {uid:account.uid,projectId:"fixture-project"};},
    service:new AccountProfileService(repository,"fixture-project")};
  const input:AccountProfileHttpInput={method:"POST",headers:{authorization:"Bearer fixture-identity",
    "x-firebase-appcheck":"fixture-proof"},body:{operation:"read",payload:{}},bodyBytes:40};
  return {deps,input,repository,proofs,counts:()=>({reads,commits})};
}
test("B01 HTTP host: verified read uses account principal and no consumed-write proof",async()=>{
 const {deps,input,proofs,counts}=setup();const r=await handleAccountProfileRequest(input,deps);
 assert.equal(r.status,200);assert.deepEqual(proofs,[false]);assert.deepEqual(counts(),{reads:1,commits:0});
 assert.equal(r.body.ok,true);
});
test("B01 HTTP host: save consumes fresh proof and returns original save identity",async()=>{
 const {deps,input,proofs,counts}=setup();const r=await handleAccountProfileRequest({...input,body:{operation:"save",
   payload:{requestId:"request-one",expectedRevision:0,change:{kind:"name",displayName:"Fixture name"}}}},deps);
 assert.equal(r.status,200);assert.deepEqual(proofs,[true]);assert.equal(counts().commits,1);
 assert.equal(r.body.ok&& (r.body.data as {requestId:string}).requestId,"request-one");
});
for(const headers of [{}, {authorization:"Bearer fixture-identity"}, {"x-firebase-appcheck":"fixture-proof"}]){
 test(`B01 HTTP host: missing credentials refused ${Object.keys(headers).join("/")}`,async()=>{
  const {deps,input,counts}=setup();const r=await handleAccountProfileRequest({...input,headers},deps);
  assert.equal(r.status,401);assert.deepEqual(counts(),{reads:0,commits:0});
 });
}
for(const actor of [{uid:"fixture-owner",projectId:"foreign"},
 {uid:"fixture-owner",projectId:"fixture-project",tenantId:"other-tenant"},
 {uid:"fixture-owner",projectId:"fixture-project",anonymous:true}]){
 test(`B01 HTTP host: invalid principal refused ${JSON.stringify(actor)}`,async()=>{
  const {deps,input,counts}=setup();const r=await handleAccountProfileRequest(input,{...deps,verifyIdToken:async()=>actor});
  assert.equal(r.status,401);assert.deepEqual(counts(),{reads:0,commits:0});
 });
}
for(const body of [null,[],{operation:["read"],payload:{}},{operation:"read",payload:{ownerUid:"foreign"}},
 {operation:"read",payload:{},ownerUid:"foreign"},{operation:"approveWorkspace",payload:{}}]){
 test(`B01 HTTP host: malformed/out-of-scope body refused ${JSON.stringify(body)}`,async()=>{
  const {deps,input,counts}=setup();const r=await handleAccountProfileRequest({...input,body},deps);
  assert.equal(r.status,400);assert.deepEqual(counts(),{reads:0,commits:0});
 });
}
test("B01 HTTP host: revoked identity stops before any account read",async()=>{
 const {deps,input,counts}=setup();const r=await handleAccountProfileRequest(input,{...deps,
   verifyIdToken:async()=>{throw new Error("fixture revoked token");}});
 assert.equal(r.status,401);assert.equal(counts().reads,0);
});
test("B01 HTTP host: consumed proof prevents a write",async()=>{
 const {deps,input,counts}=setup();const r=await handleAccountProfileRequest({...input,body:{operation:"save",payload:{}}},
  {...deps,verifyAppCheck:async()=>({alreadyConsumed:true})});
 assert.equal(r.status,401);assert.equal(counts().commits,0);
});
test("B01 HTTP host: unqualified storage is explicitly unavailable",async()=>{
 const {deps,input,counts}=setup();const r=await handleAccountProfileRequest(input,{...deps,storageQualified:false});
 assert.equal(r.status,503);assert.deepEqual(counts(),{reads:0,commits:0});
 assert.equal(r.body.ok,false);
});
test("B01 HTTP host: wrong method/oversize rejected before private data",async()=>{
 const {deps,input,counts}=setup();assert.equal((await handleAccountProfileRequest({...input,method:"GET"},deps)).status,405);
 assert.equal((await handleAccountProfileRequest({...input,bodyBytes:65537},deps)).status,413);
 assert.deepEqual(counts(),{reads:0,commits:0});
});
test("B01 HTTP host: infrastructure errors never echo private or SQL content",async()=>{
 const {deps,input,repository}=setup();repository.readAccount=async()=>{throw new Error("private fixture SQL text");};
 const r=await handleAccountProfileRequest(input,deps);assert.equal(r.status,503);
 assert.equal(JSON.stringify(r).includes("private fixture SQL"),false);
});
test("B01 HTTP host: unknown write result remains explicitly uncertain",async()=>{
 const {deps,input,repository}=setup();repository.commit=async()=>{throw new Error("fixture lost response");};
 const r=await handleAccountProfileRequest({...input,body:{operation:"save",payload:{
   requestId:"request-one",expectedRevision:0,change:{kind:"name",displayName:"Fixture name"}}}},deps);
 assert.equal(r.status,503);assert.equal(r.body.ok,false);
 if(!r.body.ok){assert.equal(r.body.error.uncertain,true);assert.equal(r.body.error.code,"profile_outcome_unknown");}
});


test("B04 HTTP prepared Save stays unavailable without its qualified original-operation wrapper",async()=>{
 const f=setup(),r=await handleAccountProfileRequest({...f.input,body:{operation:"save",payload:{requestId:"host-op",expectedRevision:0,change:{kind:"name",displayName:"Host name"},assistant:{}}}},f.deps);
 assert.equal(r.status,503);assert.deepEqual(f.counts(),{reads:0,commits:0});
});
test("B04 HTTP prepared Save retains verified actor and consumed native-write proof",async()=>{
 const f=setup();let invoked=0;
 const r=await handleAccountProfileRequest({...f.input,body:{operation:"save",payload:{requestId:"host-op",expectedRevision:0,change:{kind:"name",displayName:"Host final name"},assistant:{hostOnly:true}}}},
 {...f.deps,assistant:{async save(actor,raw){invoked++;assert.equal(actor.uid,"fixture-owner");const v=raw as {requestId:string;expectedRevision:number;change:unknown};return f.deps.service.save(actor,{requestId:v.requestId,expectedRevision:v.expectedRevision,change:v.change});},async reconcile(){throw Error("Unexpected");}}});
 assert.equal(r.status,200);assert.equal(invoked,1);assert.deepEqual(f.proofs,[true]);assert.equal(f.counts().commits,1);
});
test("B04 HTTP original reconciliation never consumes a new write proof",async()=>{
 const f=setup();let invoked=0;
 const r=await handleAccountProfileRequest({...f.input,body:{operation:"reconcile",payload:{requestId:"host-op",assistant:{hostOnly:true}}}},
 {...f.deps,assistant:{async save(){throw Error("No Save");},async reconcile(actor){invoked++;assert.equal(actor.uid,"fixture-owner");return null;}}});
 assert.equal(r.status,200);assert.equal(invoked,1);assert.deepEqual(f.proofs,[false]);assert.equal(f.counts().commits,0);
});
test("B04 HTTP uncertain confirmed-dispatch outcome keeps explicit original recovery status",async()=>{
 const f=setup();const r=await handleAccountProfileRequest({...f.input,body:{operation:"save",payload:{requestId:"host-op",expectedRevision:0,change:{kind:"name",displayName:"Host name"},assistant:{}}}},
 {...f.deps,assistant:{async save(){throw new AccountProfileError("profile_outcome_unknown",503,true);},async reconcile(){return null;}}});
 assert.equal(r.status,503);assert.equal(r.body.ok,false);if(!r.body.ok)assert.equal(r.body.error.uncertain,true);
});
