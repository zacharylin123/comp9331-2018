-- COMP9311 18s1 Project 1
--
-- MyMyUNSW Solution Template


-- Q1:
create or replace view Q1(unswid, name)
as
Select People.unswid, People.name
From People, Students, Course_enrolments
Where Course_enrolments.mark >= 85
AND Students.id = People.id
AND Students.stype = 'intl'
AND Students.id = Course_enrolments.student
Group by People.id, People.name
Having Count(Course_enrolments.course) > 20
;



-- Q2:
create or replace view Q2(unswid, name)
as
Select Rooms.unswid, Rooms.longname
From Buildings, Rooms, Room_types
Where Room_types.id = Rooms.rtype
AND Buildings.id = Rooms.building
AND Buildings.name = 'Computer Science Building'
AND Room_types.description = 'Meeting Room'
AND Rooms.capacity >= 20
;


-- Q3:
create or replace view sb_course(sbcourse)
as
select course_enrolments.course
from people, course_enrolments
where people.name = 'Stefan Bilek'
and people.id = course_enrolments.student
;
create or replace view Q3(unswid,name)
as
Select People.unswid,People.name
from course_staff, sb_course,People
where sb_course.sbcourse=course_staff.course
AND course_staff.staff = People.id
;



-- Q4:
create or replace view stu3231(unswid, name)
as
Select People.id, People.name
From Course_enrolments, Students, Subjects, Courses, People
Where Subjects.code = 'COMP3231'
AND Students.id = Course_enrolments.student
AND Courses.id = Course_enrolments.course
AND Subjects.id = Courses.subject
AND People.id = Students.id
;

create or replace view stu3331(unswid, name)
as
Select People.id, People.name
From Course_enrolments, Students, Subjects, Courses, People
Where Subjects.code = 'COMP3331'
AND Students.id = Course_enrolments.student
AND Courses.id = Course_enrolments.course
AND Subjects.id = Courses.subject
AND People.id = Students.id
;

create or replace view Q4(unswid, name)
as
Select Distinct People.unswid, People.name
From stu3331, People, Students
Where Students.id = Stu3331.unswid
AND People.id = Students.id
Except
Select Distinct People.unswid, People.name
From stu3231, People, Students
Where Students.id = Stu3231.unswid
AND People.id = Students.id
;



-- Q5:
create or replace view Q5a(num)
as
Select Count(Distinct Students.id)
AS num
From Students, Streams, Semesters,Program_enrolments, Stream_enrolments
Where Students.stype = 'local'
AND Streams.id = Stream_enrolments.stream
AND Streams.name = 'Chemistry'
AND Semesters.term = 'S1'
AND Semesters.year = '2011'
AND Semesters.id = Program_enrolments.semester
AND Students.id = Program_enrolments.student
AND Program_enrolments.id = Stream_enrolments.partOf
;

-- Q5:
create or replace view Q5b(num)
as
Select Count(Students.id)
AS num
From Students, OrgUnits, Semesters,Program_enrolments, programs, OrgUnit_types
Where Students.stype = 'intl'
AND Semesters.term = 'S1'
AND Semesters.year = '2011'
AND Semesters.id = Program_enrolments.semester
AND Students.id = Program_enrolments.student
AND OrgUnit_types.name = 'School'
AND OrgUnits.longname = 'School of Computer Science and Engineering'
AND OrgUnit_types.id = OrgUnits.utype
AND OrgUnits.id = Programs.offeredBy
AND Programs.id = Program_enrolments.program
;


-- Q6:
create or replace function Q6(text) returns text
as
$$
Select Subjects.code||' '||Subjects.name||' '||Subjects.uoc
From Subjects
Where Subjects.code = $1
;
$$ language sql;



-- Q7:
create or replace view Intlstu6(idid, count)
as
Select programs.id, Count(*)
From Students, Program_enrolments,programs
Where Students.id = Program_enrolments.student
AND Program_enrolments.program = Programs.id
AND students.stype = 'intl'
Group by Programs.id
;


create or replace view Allstu6(idid, count)
as
Select programs.id, Count(*)
From Students, Program_enrolments,programs
Where Students.id = Program_enrolments.student
AND Program_enrolments.program = Programs.id
Group by Programs.id
;



create or replace view Percent(idid, count)
as
Select Allstu6.idid, (Intlstu6.count * 1.0 / Allstu6.count * 1.0)
From Allstu6, Intlstu6
Where Allstu6.idid = Intlstu6.idid
;

create or replace view Q7(code, name)
as
Select Programs.code, Programs.name
From Programs, Percent
Where Programs.id = Percent.idid
AND Percent.count > 0.5
;



-- Q8:
create or replace view allcourse3(id)
as
Select Courses.id
From Course_enrolments, Courses
Where Courses.id = Course_enrolments.course
AND Course_enrolments.mark is not null
Group by Courses.id
;

create or replace view allcourse_count4(id)
as
Select allcourse3.id
From allcourse3,Course_enrolments
Where allcourse3.id = Course_enrolments.course
Group by allcourse3.id
Having Count(Course_enrolments.mark) >= 15
;

create or replace view allcourse_15_ave1(id, ave)
as
Select allcourse_count4.id, Avg(Course_enrolments.mark)
From allcourse_count4, Course_enrolments
Where allcourse_count4.id = Course_enrolments.course
Group by allcourse_count4.id
Order by Avg(Course_enrolments.mark) DESC
limit 1
;

create or replace view Q8(code, name, semester)
as
Select Subjects.code, Subjects.name, Semesters.name
From allcourse_15_ave1, Subjects, Semesters, Courses
Where Courses.id = allcourse_15_ave1.id
AND Courses.subject = Subjects.id
AND Semesters.id = Courses.semester
;



-- Q9:
create or replace view head_123(id)
as
Select People.id
From Affiliations, Staff_roles, People, Staff, Orgunits, OrgUnit_types
Where Affiliations.role = Staff_roles.id
AND Affiliations.staff = staff.id
AND Staff_roles.name = 'Head of School'
AND Staff.id = People.id
AND Affiliations.ending is null
AND Affiliations.isPrimary = 't'
AND Affiliations.orgunit = Orgunits.id
AND OrgUnits.utype = OrgUnit_types.id
AND OrgUnit_types.name = 'School'
;

create or replace view head_1234(id, sum)
as
Select head_123.id, Count(distinct subjects.code)
From head_123, Subjects, Courses, Course_staff, Staff
Where Subjects.id = Courses.subject
AND Course_staff.course = Courses.id
AND Course_staff.staff = Staff.id
AND Staff.id = head_123.id
Group by head_123.id
;

create or replace view Q9(name, school, email, starting, num_subjects)
as
Select People.name, Orgunits.longname, People.email, Affiliations.starting, head_1234.sum
From People, Orgunits, Affiliations, head_1234, Staff, OrgUnit_types, Staff_roles
Where People.id = head_1234.id
AND head_1234.id = Staff.id
AND Affiliations.staff = Staff.id
AND Orgunits.id = Affiliations.orgUnit
AND head_1234.sum > 0
AND Affiliations.role = Staff_roles.id
AND Staff_roles.name = 'Head of School'
AND Affiliations.ending is null
AND Affiliations.isPrimary = 't'
AND Affiliations.orgunit = Orgunits.id
AND OrgUnits.utype = OrgUnit_types.id
AND OrgUnit_types.name = 'School'
;









-- Q10:
create or replace view course_1(code)
as
Select Subjects.code
From Subjects, Semesters, Courses
Where Subjects.code like 'COMP93%'
AND Courses.subject = Subjects.id
AND  Courses.semester = Semesters.id
AND Semesters.year <= 2012
AND Semesters.year >= 2003
Group by Subjects.code
Having count(Subjects.code) = 20
;


create or replace view course_21(code,name, year, num)
as
Select Subjects.code, Subjects.name, Semesters.year, cast(sum(case when Course_enrolments.mark>=85 then 1 else 0 end)*1.0/count(*)*1.0 as numeric(4,2))
From Subjects, Semesters, Courses, Course_enrolments, course_1
Where Subjects.code = course_1.code
AND Courses.subject = Subjects.id
AND  Courses.semester = Semesters.id
AND Semesters.year <= 2012
AND Semesters.year >= 2003
AND Subjects.code like 'COMP93%'
AND Semesters.term = 'S1'
and Course_enrolments.mark >= 0
AND Course_enrolments.course = Courses.id
Group by Subjects.code, Subjects.name, Semesters.year
;

create or replace view course_22(code,name, year, num)
as
Select Subjects.code, Subjects.name, Semesters.year, cast(sum(case when Course_enrolments.mark>=85 then 1 else 0 end)*1.0/count(*)*1.0 as numeric(4,2))
From Subjects, Semesters, Courses, Course_enrolments, course_1
Where Subjects.code = course_1.code
AND Courses.subject = Subjects.id
AND  Courses.semester = Semesters.id
AND Semesters.year <= 2012
AND Semesters.year >= 2003
AND Subjects.code like 'COMP93%'
AND Semesters.term = 'S2'
and Course_enrolments.mark >= 0
AND Course_enrolments.course = Courses.id
Group by Subjects.code, Subjects.name, Semesters.year
;

create or replace view Q10(code, name, year, s1_HD_rate, s2_HD_rate)
as
Select course_21.code, course_21.name, Right(course_22.year::text, 2), course_21.num, course_22.num
From course_21, course_22
Where course_21.code = course_22.code
AND course_21.name = course_22.name
AND course_21.year = course_22.year
;
