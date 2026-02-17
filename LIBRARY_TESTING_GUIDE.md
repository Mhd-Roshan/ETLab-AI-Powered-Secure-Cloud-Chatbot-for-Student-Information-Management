# Library System Testing Guide

## Features Implemented

### 1. Add Book Functionality
- Click "Add Book" button in the header or bottom-right
- Fill in the form with book details:
  - **Required fields**: Title, Author, Category, Number of Copies
  - **Optional fields**: ISBN, Publisher, Year, Description
- Book is saved to Firebase `library_books` collection

### 2. Borrow Book
- Go to "All Books" tab
- Click "Borrow" button on any available book
- Enter student name and registration number
- Book is borrowed for 14 days
- Transaction saved to `library_transactions` collection
- Available copies count decreases

### 3. Borrowed Tab
- Shows all currently borrowed books
- Displays borrower information
- Shows due date
- Books past due date show red icon
- "Return" button to return the book

### 4. Overdue Tab
- Shows only books that are past their due date
- Red-themed cards for urgency
- Shows days overdue
- "Return" button to return the book

### 5. Return Book
- Click "Return" button on any borrowed/overdue book
- Transaction status updated to "returned"
- Available copies count increases

## Testing Overdue Books

To test the overdue functionality, you need books with past due dates. You can:

1. **Manual Testing** (Recommended):
   - Borrow a book normally (gets 14 days due date)
   - Go to Firebase Console
   - Navigate to `library_transactions` collection
   - Find your transaction
   - Edit the `dueDate` field to a past date (e.g., 7 days ago)
   - Refresh the app - book will appear in Overdue tab

2. **Using Firebase Console**:
   - Go to Firebase Console > Firestore Database
   - Add a document to `library_transactions` with:
     ```
     bookId: [any book ID from library_books]
     bookTitle: "Test Book"
     bookAuthor: "Test Author"
     bookIsbn: "123456789"
     borrowerName: "Test Student"
     borrowerRegNo: "MCA001"
     borrowDate: [timestamp - 20 days ago]
     dueDate: [timestamp - 6 days ago]
     status: "borrowed"
     ```

## Database Collections

### library_books
- title, author, isbn, category
- publisher, year
- totalCopies, copiesAvailable
- isAvailable, description
- addedDate

### library_transactions
- bookId, bookTitle, bookAuthor, bookIsbn
- borrowerName, borrowerRegNo
- borrowDate, dueDate, returnDate
- status (borrowed/returned)
- createdAt

## Stats Cards
- **Total Books**: Count of all books in library
- **Borrowed**: Count of currently borrowed books (status = 'borrowed')
- **Overdue**: Count of borrowed books past due date
