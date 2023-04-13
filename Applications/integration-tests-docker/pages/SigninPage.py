from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions

from .BasePage import BasePage, BasePageInput


class UsernameInput(BasePageInput):
    locator = (By.ID, "signInFormUsername")


class PasswordInput(BasePageInput):
    locator = (By.ID, "signInFormPassword")


class SigninPage(BasePage):
    """Signin page"""

    username = UsernameInput()
    password = PasswordInput()

    def __init__(self,  *args):
        super().__init__(*args)
        self.wait.until(expected_conditions.title_contains('Signin'))

    def click_signin_button(self):
        """Change Page"""
        self.driver.find_element(By.NAME, "signInSubmitButton").click()
