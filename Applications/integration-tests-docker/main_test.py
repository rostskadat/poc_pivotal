#!/usr/bin/env python
"""Runs the integration tests.

This is an example of an integration tests suite.
It takes 2 parameter (username & password) of the Cognito User used for integration testing.

Returns:
    int: 0 for success, 1 otherwise
"""
import os
import unittest
from time import sleep

import pages
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.support.ui import WebDriverWait
from webdriver_manager.chrome import ChromeDriverManager


class AppIntegrationTests(unittest.TestCase):

    BASE_URL = os.getenv("BASE_URL")
    COGNITO_USERNAME = os.getenv("COGNITO_USERNAME")
    COGNITO_PASSWORD = os.getenv("COGNITO_PASSWORD")
    TAKE_SCREENSHOT = os.getenv("TAKE_SCREENSHOT", "False") == "True"
    MANAGED_BY_AWS = "MANAGED_BY_AWS" in os.environ

    def setUp(self):
        if not self.COGNITO_USERNAME or not self.COGNITO_PASSWORD or not self.BASE_URL:
            self.fail(f"""The environment variables have not been set.
            All are required ('COGNITO_USERNAME', 'COGNITO_PASSWORD', 'BASE_URL').
            """
                      )

        print("Test Execution Started")
        options = webdriver.ChromeOptions()
        if self.MANAGED_BY_AWS:
            options.add_argument('--headless')
        options.add_argument('--disable-gpu')
        options.add_argument('--no-sandbox')
        self.driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=options)
        self.driver.implicitly_wait(10)
        self.driver.get(self.BASE_URL)
        self.wait = WebDriverWait(self.driver, 30)
        self.step = 0

    def test_navigation(self):
        self._take_screenshot()
        signin_page = pages.SigninPage(self.driver)
        signin_page.username = self.COGNITO_USERNAME
        signin_page.password = self.COGNITO_PASSWORD
        self._take_screenshot()
        signin_page.click_signin_button()
        home_page = pages.HomePage(self.driver)
        self.driver.set_window_size(1280,1024)
        self.assertEqual(home_page.current_user, self.COGNITO_USERNAME)
        self._take_screenshot()
        home_page.click_api_gw_link()
        api_gw_page = pages.ApiGwPage(self.driver)
        # self.assertIn('Authorization', api_gw_page.through_apigw_result)
        # self.assertIn('Authorization', api_gw_page.through_webapp_result)

    def tearDown(self):
        sleep(2)
        self.driver.quit()

    def _take_screenshot(self, name: str = None):
        if not self.TAKE_SCREENSHOT:
            return
        if name:
            screenshot_name = name
        else:
            screenshot_name = f"screenshot-{self.step}.png"
        self.driver.save_screenshot(screenshot_name)
        self.step += 1


if __name__ == "__main__":
    unittest.main()
