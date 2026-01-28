import asyncio
from playwright.async_api import async_playwright

async def run():
    async with async_playwright() as p:
        browser = await p.chromium.launch()
        context = await browser.new_context(viewport={'width': 400, 'height': 800})
        page = await context.new_page()

        await page.goto('http://localhost:8080')
        await asyncio.sleep(5)

        # Start Screen -> Selection
        for _ in range(4):
            await page.keyboard.press("Tab")
            await asyncio.sleep(0.1)
        await page.keyboard.press("Enter")
        await asyncio.sleep(2)

        # Selection -> Creation
        for _ in range(4):
            await page.keyboard.press("Tab")
            await asyncio.sleep(0.1)
        await page.keyboard.press("Enter")
        await asyncio.sleep(2)

        # Creation -> Home
        await page.keyboard.type("Tester")
        await page.keyboard.press("Tab")
        await page.keyboard.press("Enter")
        await asyncio.sleep(2)

        # Home Screen
        await page.screenshot(path='/home/jules/verification/final_home_no_backstory.png')

        # Click Forge Backstory
        await page.keyboard.press("Tab")
        await page.keyboard.press("Enter")
        await asyncio.sleep(2)
        await page.screenshot(path='/home/jules/verification/final_backstory_screen.png')

        await browser.close()

asyncio.run(run())
