import test from "node:test";
import assert from "node:assert/strict";
import type { DataConnect } from "firebase-admin/data-connect";
import {DataConnectAccountProfileRepository,ACCOUNT_PROFILE_COMMIT_SQL} from "./profile_dataconnect_store.js";
import {AccountProfileError,type AccountProfileCommit,type AccountProfile} from "./profile_service.js";
const owner="fixture-owner",stamp="2026-10-27T00:00:00.000Z",fingerprint="a".repeat(64);
const profile:AccountProfile={ownerUid:owner,revision:1,updatedAt:stamp,displayName:"Fixture name",
 addresses:[],selectedAddressId:null,invoiceProfiles:[]};
const value:AccountProfileCommit={ownerUid:owner,requestId:"request-one",fingerprint,expectedRevision:0,profile};
const saved={ownerUid:owner,requestId:value.requestId,fingerprint,profile};
type Call={query:string;variables:unknown};
function fixture(responses:unknown[]){
 const calls:Call[]=[];
 async function invoke<R,V>(query:string,options?:{variables?:V}):Promise<{data:R}>{
  calls.push({query,variables:options?.variables});if(!responses.length)throw new Error("Fixture exhausted");
  return {data:responses.shift() as R};
 }
 const transport={executeGraphql:invoke,executeGraphqlRead:invoke} as Pick<DataConnect,"executeGraphql"|"executeGraphqlRead">;
 return {store:new DataConnectAccountProfileRepository(transport),calls};
}
const row=(extra:Record<string,unknown>={})=>({appUser:{uid:owner,status:"ACTIVE",displayName:"Fixture name",
 updatedAt:stamp,profileRevision:1,profileDataJson:JSON.stringify(profile),...extra}});
const rejects=(p:Promise<unknown>)=>assert.rejects(p,(e:unknown)=>e instanceof AccountProfileError&&e.status===503);
test("B01 adapter host: canonical Profile read is owner-filtered",async()=>{
 const {store,calls}=fixture([row()]);assert.deepEqual((await store.readAccount(owner))?.profile,profile);
 assert.deepEqual(calls[0]?.variables,{uid:owner});assert.match(calls[0]!.query,/appUser\(key: \{uid:\$uid\}\)/u);
});
test("B01 adapter host: legacy account has no invented addresses/invoices",async()=>{
 const {store}=fixture([row({profileRevision:0,profileDataJson:null})]);
 const r=await store.readAccount(owner);assert.equal(r?.profile?.revision,0);
 assert.deepEqual(r?.profile?.addresses,[]);assert.deepEqual(r?.profile?.invoiceProfiles,[]);
});
for(const extra of [{uid:"foreign"},{status:"invented"},{profileRevision:-1},
 {profileRevision:2},{profileDataJson:"broken"},{displayName:"drifted name"},
 {profileRevision:1,profileDataJson:null},
 {profileDataJson:JSON.stringify({...profile,ownerUid:"foreign"})},
 {profileDataJson:JSON.stringify({...profile,workspaceApproved:true})}]){
 test(`B01 adapter host: invalid durable data fails closed ${JSON.stringify(extra)}`,async()=>{
  const {store}=fixture([row(extra)]);await rejects(store.readAccount(owner));
 });
}
test("B01 adapter host: unknown account stays missing",async()=>{
 const {store}=fixture([{appUser:null}]);assert.equal(await store.readAccount(owner),undefined);
});
test("B01 adapter host: commit uses one parameterized atomic statement",async()=>{
 const {store,calls}=fixture([{committed:{receipt_json:JSON.stringify(saved)}}]);
 const r=await store.commit(value);assert.equal(r.state,"applied");assert.deepEqual("receipt" in r?r.receipt:undefined,saved);
 assert.equal(calls.length,1);assert.equal(calls[0]!.query.includes(ACCOUNT_PROFILE_COMMIT_SQL),true);
 assert.equal(calls[0]!.query.includes(owner),false);
 assert.deepEqual(Object.keys(calls[0]!.variables as object).sort(),["expectedRevision","fingerprint","profile","receipt","requestId","uid"]);
});
test("B01 adapter host: explicit miss rereads status and original receipt",async()=>{
 const {store}=fixture([{committed:null},row(),{receipts:[{receipt_json:JSON.stringify(saved)}]}]);
 const r=await store.commit(value);assert.equal(r.state,"replayed");
});
test("B01 adapter host: newer revision without receipt cannot pass as success",async()=>{
 const {store}=fixture([{committed:null},row(),{receipts:[{receipt_json:null}]}]);
 assert.deepEqual(await store.commit(value),{state:"conflict"});
});
for(const status of ["RESTRICTED","DELETED"]){
 test(`B01 adapter host: ${status} returns status after private fields are erased`,async()=>{
  const {store}=fixture([row({status,displayName:null,profileDataJson:null})]);
  assert.deepEqual(await store.readAccount(owner),{uid:owner,status,profile:null});
 });
 test(`B01 adapter host: ${status} cannot be reset by Profile write`,async()=>{
  const {store}=fixture([{committed:null},row({status})]);assert.deepEqual(await store.commit(value),{state:"restricted"});
 });
}
for(const raw of ["not-json",JSON.stringify({...saved,ownerUid:"foreign"}),
 JSON.stringify({...saved,fingerprint:"bad"}),JSON.stringify({...saved,extra:"unverified"})]){
 test(`B01 adapter host: malformed/misattributed receipt rejected ${raw}`,async()=>{
  const {store}=fixture([{receipts:[{receipt_json:raw}]}]);await rejects(store.readReceipt(owner,"request-one"));
 });
}
test("B01 adapter host: a changed fingerprint never qualifies an original mutation",async()=>{
 const {store}=fixture([{committed:{receipt_json:JSON.stringify({...saved,fingerprint:"b".repeat(64)})}}]);
 await assert.rejects(store.commit(value),(e:unknown)=>e instanceof AccountProfileError&&e.code==="profile_request_conflict");
});
test("B01 adapter host: namespace collision/malformed revision stopped before SQL",async()=>{
 const {store,calls}=fixture([]);await rejects(store.commit({...value,ownerUid:"foreign"}));
 await rejects(store.commit({...value,expectedRevision:1}));assert.equal(calls.length,0);
});
