import {test,expect} from '@playwright/test';
test('discovery filters, consent, and local plan persistence',async({page},info)=>{
 const errors:string[]=[];page.on('pageerror',e=>errors.push(e.message));
 await page.goto('/');await expect(page.getByRole('heading',{name:/Find your people/})).toBeVisible();
 await expect(page.locator('.profile-card')).toHaveCount(3);
 await page.getByRole('button',{name:/Photography/}).click();await expect(page.locator('.profile-card')).toHaveCount(1);
 await page.getByRole('button',{name:'All vibes',exact:false}).click();
 await page.locator('.profile-card').first().getByRole('button',{name:'Say hello'}).click();await expect(page.locator('.profile-card').first().getByRole('button',{name:'Request sent'})).toBeDisabled();
 await page.getByRole('button',{name:'Create my Pujo plan'}).click();const dialog=page.getByRole('dialog');
 await dialog.getByLabel('Display name').fill('Puja');await dialog.getByLabel('A little about you').fill('Here for photography and festive lights.');await dialog.getByRole('button',{name:'Save my Pujo plan'}).click();await expect(dialog).not.toBeVisible();
 await page.reload();if(info.project.name==='mobile')await page.getByRole('button',{name:'Toggle navigation'}).click();
 await page.getByRole('button',{name:'My Pujo plan',exact:true}).click();await expect(page.getByRole('heading',{name:'Your Pujo, planned.'})).toBeVisible();
 await page.getByRole('button',{name:'Edit my plan'}).click();await expect(page.getByLabel('Display name')).toHaveValue('Puja');await page.getByRole('button',{name:'Close dialog'}).click();
 expect(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth)).toBe(true);
 if(info.project.name==='mobile')await page.getByRole('button',{name:'Toggle navigation'}).click();await page.getByRole('button',{name:'Discover',exact:true}).click();
 await page.screenshot({path:`tests/${info.project.name}.png`,fullPage:true,animations:'disabled'});expect(errors).toEqual([]);
});
test('squad creation and safety reminder',async({page},info)=>{
 await page.goto('/');if(info.project.name==='mobile')await page.getByRole('button',{name:'Toggle navigation'}).click();await page.getByRole('button',{name:'Squads',exact:true}).click();
 await page.getByRole('button',{name:'Create a squad',exact:true}).click();const dialog=page.getByRole('dialog');await dialog.getByLabel('Squad name').fill('Evening explorers');await dialog.getByLabel('The plan',{exact:true}).fill('Meet in a public place and visit two pandals.');await dialog.getByRole('button',{name:'Create squad',exact:true}).click();await expect(page.getByRole('heading',{name:'Evening explorers'})).toBeVisible();
 await page.getByRole('button',{name:'Safety first'}).click();await page.getByLabel('Trusted contact (private)').fill('Test contact');await page.getByRole('button',{name:'Set check-in'}).click();await expect(page.locator('.success')).toContainText('Reminder at');await page.getByRole('button',{name:'I’m okay'}).click();await expect(page.locator('.success')).toHaveCount(0);
});
