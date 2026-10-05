import {test} from 'node:test';
import assert from 'node:assert/strict';
import {compatibility,defaultPlan,demoPlans} from '../lib/data.ts';
test('identical complete plans have 100% plan compatibility',()=>assert.equal(compatibility({...defaultPlan,bio:'Hello',avatar:'https://example.com/a.jpg'},{...defaultPlan,bio:'Hello',avatar:'https://example.com/b.jpg'}),100));
test('romantic intent is a hard mutual filter',()=>{assert.equal(compatibility(defaultPlan,{...demoPlans[0],intent:'Date'}),0);assert.equal(compatibility({...defaultPlan,intent:'Date'},demoPlans[0]),0);});
test('non-overlapping schedules receive no schedule points',()=>{const complete={...defaultPlan,bio:'Hello',avatar:'https://example.com/a.jpg'};assert.equal(compatibility(complete,{...complete,start:10,end:12}),70);assert.equal(compatibility(complete,{...complete,day:'Navami'}),70);});
test('shared route and interest reward ranking',()=>{assert.ok(compatibility(defaultPlan,demoPlans[0])>compatibility(defaultPlan,demoPlans[2]));});
test('empty routes and interests never return NaN',()=>{const score=compatibility({...defaultPlan,pandals:[],interests:[]},{...demoPlans[0],pandals:[],interests:[]});assert.ok(Number.isFinite(score));assert.ok(score>=0&&score<=100);});
