from selenium.webdriver.support.ui import WebDriverWait


class BasePage(object):
    """Base class to all pages"""

    def __init__(self, driver, default_wait=30):
        self.driver = driver
        self.wait = WebDriverWait(driver, default_wait)


class BasePageInput(object):
    """Base class all input element on a page."""

    def __set__(self, page: BasePage, value):
        """Sets the input value"""
        page.wait.until(lambda driver: driver.find_element(*self.locator))
        page.driver.find_element(*self.locator).clear()
        page.driver.find_element(*self.locator).send_keys(value)

    def __get__(self, page: BasePage, _):
        """Gets the input value"""
        page.wait.until(lambda driver: driver.find_element(*self.locator))
        return page.find_element(*self.locator).get_attribute("value")


class BasePageElement(object):
    """Base class to all element (i.e. span, div, etc.) on a page."""

    def __get__(self, page: BasePage, _):
        """Gets the element inner text. I.e. '<span>myText</span>' will return 'myText'"""
        page.wait.until(lambda driver: driver.find_element(*self.locator))
        return page.driver.find_element(*self.locator).text
