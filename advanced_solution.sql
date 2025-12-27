select * from books;
select * from branch;
select * from employees;
select * from issued_status;
select * from return_status;
select * from members;

-- Porject Task--
--Basic Operations
--Task 1. Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"
insert into books
values 
('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');

--Task 2: Update an Existing Member's Address
update members
set member_address = '999 Main st'
where member_id ='C101';
member_address = "999 Main st";

__Task 3: Delete a Record from the Issued Status Table -- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.
delete from issued_status
where issued_id = 'IS121';

--Task 4: Retrieve All Books Issued by a Specific Employee -- Objective: Select all books issued by the employee with emp_id = 'E101'.
select  *
from issued_status 
where issued_emp_id = 'E101';

--Task 5: List Members Who Have Issued More Than One Book -- Objective: Use GROUP BY to find members who have issued more than one book.
select issued_emp_id ,
       count(issued_id) as total
from issued_status
group by 1
having count(issued_id) > 1;

--Task 6: Create Summary Tables: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt**
create table book_cnts
as
select
       b.isbn,
	   b.book_title,
      count(issued_id) as number_issued
from books as b
join
issued_status as ist
on ist.issued_book_isbn = b.isbn
GROUP BY 1,2;
``
--Task 7. Retrieve All Books in a Specific Category:
select * from books
where category = 'Classic';

--Task 8: Find Total Rental Income by Category:
select 
     b.category,
	 sum(b.rental_price),
	 count(*)
from books as b
join
issued_status as ist
on ist.issued_book_isbn = b.isbn
GROUP BY 1;

--Task 9 : List Members Who Registered in the Last 180 Days:
select * from members where reg_date >= current_date - interval '180 days';

insert into members(member_id,member_name,member_address,reg_date)
values
('C116', 'Sam','7888 str','2025-11-26'),
('C120','Ruby','777 Pine St','2025-12-12');

--Task 10 :List Employees with Their Branch Manager's Name and their branch details:
select 
      el.*,
	  ell.emp_name as manager ,
	  br.manager_id,
	  br.branch_address
from employees as el
JOIN
branch as br
on el.branch_id = br.branch_id
JOIN
employees as ell
on br.manager_id = ell.emp_id; 

--Task 11. Create a Table of Books with Rental Price Above a Certain Threshold:
create table expensive_books
as 
select * from books 
where rental_price > 6;
select * from expensive_books;

--Task 12: Retrieve the List of Books Not Yet Returned

select 
      distinct ist.issued_book_name,
	   count(ist.issued_book_name)
from issued_status as ist
left join
return_status as rs 
on ist.issued_id = rs.issued_id
where rs.return_id is  null
GROUP BY 1;

### Advanced SQL Operations

--Task 13: Identify Members with Overdue Books
--Write a query to identify members who have overdue books (assume a 30-day return period). Display the member's name, book title, issue date, and days overdue.

select  
      ist.issued_member_id,
	  m.member_name,
	  b.book_title,
	  ist.issued_date,
	  rs.return_date,
	  current_date - ist.issued_date as overdue
from issued_status as ist
join
members as m
on m.member_id = ist.issued_member_id
join 
books as b
on ist.issued_book_isbn = b.isbn 
left join
return_status as rs
on rs.issued_id = ist.issued_id
where return_date is null and (current_date -  issued_date)  > 30
order by 1;


Task 14: Update Book Status on Return
Write a query to update the status of books in the books table to "available" when they are returned (based on entries in the return_status table).


CREATE OR REPLACE PROCEDURE add_return_records(p_return_id VARCHAR(10), p_issued_id VARCHAR(10), p_book_quality VARCHAR(10))
LANGUAGE plpgsql
AS $$

DECLARE
    v_isbn VARCHAR(50);
    v_book_name VARCHAR(80);
    
BEGIN
   
    INSERT INTO return_status(return_id, issued_id, return_date, book_quality)
    VALUES
    (p_return_id, p_issued_id, CURRENT_DATE, p_book_quality);

    SELECT 
        issued_book_isbn,
        issued_book_name
        INTO
        v_isbn,
        v_book_name
    FROM issued_status
    WHERE issued_id = p_issued_id;

    UPDATE books
    SET status = 'yes'
    WHERE isbn = v_isbn;

    RAISE NOTICE 'Thank you for returning the book: %', v_book_name;
    
END;
$$


issued_id = IS135
ISBN = WHERE isbn = '978-0-307-58837-1'

SELECT * FROM books
WHERE isbn = '978-0-307-58837-1';

SELECT * FROM issued_status
WHERE issued_book_isbn = '978-0-307-58837-1';

SELECT * FROM return_status
WHERE issued_id = 'IS135';


CALL add_return_records('RS138', 'IS135', 'Good');

CALL add_return_records('RS148', 'IS140', 'Good');


/*
Task 15: Branch Performance Report
Create a query that generates a performance report for each branch, showing the number of books issued, the number of books returned, and the total revenue generated from book rentals.
*/
CREATE TABLE branch_reports
as
select 
      br.branch_id,
	  br.manager_id,
	  sum(b.rental_price) as total_revenue,
	  count(ist.issued_id) as books_issued,
	  count(rs.return_id) as books_returned	
from issued_status as ist
join
employees as el 
on el.emp_id = ist.issued_emp_id
join 
branch as br
on br.branch_id = el.branch_id
 left join
return_status as rs
on rs.issued_id =ist.issued_id
join 
books as b
on b.isbn = ist.issued_book_isbn
GROUP BY 1,2;

select * from branch_reports;

Task 16: CTAS: Create a Table of Active Members
Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who have issued at least one book in the last 2 months.

create table active_members
as 
select *from members
where member_id in(
     select
        distinct(issued_member_id)
        from issued_status
        where issued_date >=  current_date - interval  '2 month'
);

select * from active_members;

/*
Task 17: Find Employees with the Most Book Issues Processed
Write a query to find the top 3 employees who have processed the most book issues. Display the employee name, number of books processed, and their branch.
*/
select 
     e.emp_name,
	 br.*,
	 count(	 ist.issued_id)
from employees as e
join
issued_status as ist
on ist.issued_emp_id = e.emp_id
join
branch as br
on e.branch_id = br.branch_id
group by 1,2;

/*
Task 18: Identify Members Issuing High-Risk Books
Write a query to identify members who have issued books more than twice with the status "damaged" in the books table. Display the member name, book title, and the number of times they've issued damaged books.    
*/
select 
       m.member_name,
	   b.book_title,
       count( rs.book_quality) as damaged_status
from return_status as rs
join 
issued_status as ist
on ist.issued_id = rs.issued_id
join
members as m
on ist.issued_member_id = m.member_id
join
books as b 
on b.isbn = ist.issued_book_isbn
where rs.book_quality ='Damaged'
group by 1,2;


/*
Task 19: Stored Procedure
Objective: Create a stored procedure to manage the status of books in a library system.
    Description: Write a stored procedure that updates the status of a book based on its issuance or return. Specifically:
    If a book is issued, the status should change to 'no'.
    If a book is returned, the status should change to 'yes'.
*/

create or replace procedure issue_book(p_issued_id varchar(10),p_issued_member_id varchar(10),p_issued_book_isbn varchar(25),p_issued_emp_id varchar(10))
language plpgsql
AS $$
DECLARE
   	  v_status varchar(10);
BEGIN
       select status 
	          into
			  v_status
	   from books
	   where isbn = p_issued_book_isbn;
	   
	IF  v_status ='yes' THEN
	    insert into issued_status(issued_id,issued_member_id,issued_date,issued_book_isbn,issued_emp_id)
		values
		(p_issued_id,p_issued_member_id ,current_date,p_issued_book_isbn ,p_issued_emp_id);

         update books
		 set status ='no'
		 where isbn = p_issued_book_isbn;
		  RAISE NOTICE 'Book records added successfully for book isbn : %',p_issued_book_isbn;
    ELSE 
           RAISE NOTICE 'Sorry to inform you the book you requested is unavailabe book isbn : %',p_issued_book_isbn;
	END IF ;
END;
$$	

call issue_book('IS155','C108','978-0-553-29698-2','E106');

call issue_book('IS156','C108','978-0-7432-7357-1','E106');



Task 20: Create Table As Select (CTAS)
Objective: Create a CTAS (Create Table As Select) query
 to identify overdue books and calculate fines.
 
create table overdue_book_fines
as
 select 
        ist.issued_id,
		ist.issued_book_name,
		ist.issued_date,
		b.rental_price,
		 (CURRENT_DATE - ist.issued_date - 90) AS overdue_days,
        (CURRENT_DATE - ist.issued_date - 90) * b.rental_price AS total_fine
 from issued_status as ist
 join
 books as b
on ist.issued_book_isbn =b.isbn 
where b.status ='yes' and ist.issued_date <= current_date - interval '90 days'
order by 1,2;


select * from overdue_book_fines;
 