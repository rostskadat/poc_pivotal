import json
from http import HTTPStatus
from typing import List

from flask import request
from flask_restx import Api, Resource, fields
from microservice.api import blueprint
from microservice.api.models import Book, BookDetails

api = Api(blueprint)

ns = api.namespace("books", description="CRUD Operations for Books")
api.add_namespace(ns)

book_detail_model = api.model(
    "BookDetail",
    {
        "key": fields.String(description='The key identifing the detail', required=True),
        "value": fields.String(description='The value for this detail', required=False),
    }
)

book_model = api.model(
    "Book",
    {
        "id": fields.Integer,
        "title": fields.String(description='The title of the book', required=True),
        "author": fields.String(description='The author of the book', required=True),
        "details": fields.List(fields.Nested(book_detail_model)),
    },
)

books_model = api.model(
    "Books",
    {
        "books": fields.List(fields.Nested(book_model)),
    },
)

book_parser = api.parser()
book_parser.add_argument("id", type=int, location="form")
book_parser.add_argument("title", type=str, location="form")
book_parser.add_argument("author", type=str, location="form")
#book_parser.add_argument('cover', type=FileStorage, location='files')

detail_parser = api.parser()
detail_parser.add_argument("key", type=str, location="form")
detail_parser.add_argument("value", type=str, location="form")

books_in_memory: List[Book] = [
    {
        "id": 0,
        "title": "Crime of the Spanish Librarian",
        "author": "Richard T. Coleman",
        "details": [
            {"key": "ISBN", "value": "1234"}
        ],
    },
    {
        "id": 1,
        "title": "2938: Rebirth",
        "author": "Anabel K. Russell",
        "details": [
            {"key": "ISBN", "value": "1234"}
        ],
    },
]

@ns.route("/", endpoint='books')
class BooksApi(Resource):

    next_book_id: int = len(books_in_memory)

    @api.doc(description="Return the list of all known books")
    @api.marshal_list_with(book_model)
    @api.response(200, "Success", books_model)
    def get(self):
        return books_in_memory

    @api.doc(description="Add a new book")
    @api.expect(book_parser)
    @api.marshal_with(book_model)
    @api.response(200, "Success")
    def post(self):
        book = book_parser.parse_args()
        book['id'] = self.next_book_id
        if 'details' not in book: 
            book['details'] = []
        books_in_memory.append(book)
        self.next_book_id += 1
        return book


@ns.route("/<int:book_id>")
@ns.param('book_id', 'The book id')
class BookApi(Resource):

    def _lookup(self, book_id):
        return next((b for b in books_in_memory if b["id"] == book_id))

    @api.doc(description="Get the book with the given `book_id`")
    @api.response(200, "Success", book_model)
    @api.response(404, "Book not found")
    def get(self, book_id: int) -> Book:
        try:
            return self._lookup(book_id)
        except StopIteration:
            return api.abort(404, "Book not found")

    @api.doc(description="Update the book with the given `book_id` with new details")
    @api.expect(detail_parser)
    @api.response(201, "Book updated", book_model)
    @api.response(404, "Book not found")
    def post(self, book_id: int) -> None:
        args = detail_parser.parse_args()
        try:
            if book := self._lookup(book_id):
                book["details"].append(args)
            return book
        except StopIteration:
            return api.abort(404, "Book not found")
