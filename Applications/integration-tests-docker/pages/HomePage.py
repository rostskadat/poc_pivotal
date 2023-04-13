from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions

from .BasePage import BasePage, BasePageElement


class CurrentUserElement(BasePageElement):
    locator = (By.ID, "current_user")

class HomePage(BasePage):
    """Home page action methods come here."""

    current_user = CurrentUserElement()

    def __init__(self,  *args):
        super().__init__(*args)
        self.wait.until(expected_conditions.title_contains('HOME'))

    def click_api_gw_link(self):
        """Change Page"""
        #self.driver.find_element(By.ID, "api-gw-link").click()
        self.driver.find_element(By.XPATH, "//a[@href='/api-gw.html'][1]").click()
