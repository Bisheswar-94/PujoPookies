export const intents = ['All vibes','Friend','Date','Squad','Pandal Partner','Food Partner','Photography Partner'];
export const days = ['Sashthi','Saptami','Ashtami','Navami','Dashami'];
export const areas = ['South Kolkata','North Kolkata','Central Kolkata','Salt Lake'];
export const pandals = [
 {id:'1',name:'Ekdalia Evergreen',area:'South Kolkata',tag:'The classic Pujo stop',image:'photo-1604629142630-84a2b879e1df'},
 {id:'2',name:'Ballygunge Cultural',area:'South Kolkata',tag:'Art, tradition & a little magic',image:'photo-1518098268026-4e89f1a2cd8e'},
 {id:'3',name:'Kumartuli Park',area:'North Kolkata',tag:'Where the city creates its magic',image:'photo-1606293926249-01341c9a5c15'},
 {id:'4',name:'College Square',area:'Central Kolkata',tag:'Lights reflected on the water',image:'photo-1514222134-b57cbb8ce073'},
 {id:'5',name:'Sreebhumi',area:'Salt Lake',tag:'A grand evening with your people',image:'photo-1548013146-72479768bada'}
];
export type Plan = {id:string;user_id:string;name:string;age:number;bio:string;avatar:string;day:string;start:number;end:number;area:string;intent:string;interests:string[];pandals:string[];budget:string;visible?:boolean;verified?:boolean};
export const demoPlans:Plan[] = [
 {id:'demo-1',user_id:'riya',name:'Riya',age:24,bio:'Here for the lights, the late-night adda, and one more phuchka. ✨',avatar:'photo-1534528741775-53994a69daeb',day:'Ashtami',start:17,end:22,area:'South Kolkata',intent:'Pandal Partner',interests:['Pandal hopping','Street food','Photography'],pandals:['1','2'],budget:'₹500–1,000'},
 {id:'demo-2',user_id:'arjun',name:'Arjun',age:26,bio:'Camera in hand, no route in mind. Let’s find the city’s little stories.',avatar:'photo-1500648767791-00dcc994a43e',day:'Ashtami',start:16,end:21,area:'South Kolkata',intent:'Photography Partner',interests:['Photography','Pandal hopping','Art'],pandals:['1','2'],budget:'₹500–1,000'},
 {id:'demo-3',user_id:'ishani',name:'Ishani',age:23,bio:'New to Kolkata. Looking for good company and excellent mishti doi.',avatar:'photo-1524504388940-b1c1722653e1',day:'Ashtami',start:18,end:23,area:'South Kolkata',intent:'Friend',interests:['Street food','Music','Pandal hopping'],pandals:['2'],budget:'Under ₹500'},
 {id:'demo-4',user_id:'dev',name:'Dev',age:25,bio:'A long walk, a good conversation, and all the festive chaos.',avatar:'photo-1506794778202-cad84cf45f1d',day:'Navami',start:17,end:22,area:'North Kolkata',intent:'Date',interests:['Music','Art','Street food'],pandals:['3'],budget:'₹500–1,000'}
];
export const defaultPlan:Plan = {id:'my-plan',user_id:'me',name:'You',age:22,bio:'',avatar:'',day:'Ashtami',start:17,end:22,area:'South Kolkata',intent:'Pandal Partner',interests:['Pandal hopping','Street food','Photography'],pandals:['1','2'],budget:'₹500–1,000'};
export function compatibility(a:Plan,b:Plan) {
 if((a.intent==='Date') !== (b.intent==='Date')) return 0;
 const overlap=Math.max(0,Math.min(a.end,b.end)-Math.max(a.start,b.start));
 const schedule=a.day===b.day?overlap/Math.max(a.end-a.start,b.end-b.start):0;
 const route=a.pandals.filter(p=>b.pandals.includes(p)).length/Math.max(a.pandals.length,b.pandals.length,1);
 const interest=a.interests.filter(i=>b.interests.includes(i)).length/Math.max(a.interests.length,b.interests.length,1);
 return Math.round(30*schedule+25*(a.area===b.area?Math.max(.6,route):route)+20*(a.intent===b.intent?1:.6)+15*interest+10*(b.bio&&b.avatar?1:.5));
}
export const photo=(id:string,w=700)=>id.startsWith('https://')?id:`https://images.unsplash.com/${id}?auto=format&fit=crop&w=${w}&q=85`;
