
from typing import List


class BookDetails(object):
    id: int
    isbn: str


class Book(object):
    id: int
    title: str
    author: str
    details: List[BookDetails]
