--Q1


create or replace function Q11(course_id integer)
    returns integer
as $$
declare num1 integer;
begin
select count(students.id) into num1
from course_enrolments, students
where course_enrolments.course = course_id
AND students.id = course_enrolments.student;
return num1;
end;

$$ language plpgsql;






create or replace function Q12(course_id integer)
    returns integer
as $$
declare num_waitlist integer;
begin
select count(students.id) into num_waitlist
from Course_enrolment_waitlist, students
where Course_enrolment_waitlist.course = course_id
AND students.id = Course_enrolment_waitlist.student;
return num_waitlist;
end;
$$ language plpgsql;




drop type if exists RoomRecord cascade;
create type RoomRecord as (valid_room_number integer, bigger_room_number integer);

create or replace function Q1(course_id integer)
    returns RoomRecord
as $$

declare result RoomRecord;
begin
if not exists(select * from courses where courses.id = $1) then
  raise exception 'INVALID COURSEID';
else
select count(*) into result.valid_room_number
from Rooms
where Rooms.capacity >= (select * from  Q11($1));
--if result.valid_room_number is null then raise exception'INVALID COURSEID';
--if (not found) then raise exception'INVALID COURSEID', course_id;
--end if;
--select * into result
select count(*) into result.bigger_room_number
from Rooms
where Rooms.capacity >= (select * from  Q11($1)) + (select * from  Q12($1))
;
--if result.bigger_room_number is null then raise exception'INVALID COURSEID';
--if (not found) then raise exception'INVALID COURSEID', course_id;
end if;
return result;
end;
--... SQL statements, possibly using other views/functions defined by you ...
$$ language plpgsql;







--Q2:

---median
create or replace function median(numeric[])
  returns numeric as
  $$
  select case
  when array_upper($1,1) = 0 THEN NULL
  when mod(arry_upper($1,1),2) = 1
  then asorted[ceiling(array_upper(asorted,1)/ 2.0 )]
  else ((asorted[ceiling(array_upper(asorted,1)/ 2.0 )] + asorted[ceiling(array_upper(asorted,1)/ 2.0 )+1])/2.0) end
  from (select array(select($1)[n] FROM
  generate_series(1,arry_upper($1,1)) as n
  where ($1)[n] is not NULL
  order by ($1)[n]
) as asorted) as foo;
$$
language sql immutable;

drop aggregate if exists median(numeric);
create aggregate median(numeric)(
  sfunc = array_append,
  stype = numeric[],
  finalfunc = median
);

------median

drop type if exists num2 cascade;
create type num2 as (cid integer, average_mark integer, highest_mark integer, median_mark integer, totalEnrols integer);

create or replace function Q212(staff_id integer)
	returns setof num2
as $$
declare result num2;
begin
return query
select cast(Course_staff.course as integer), cast(round(avg(Course_enrolments.mark))as integer),
cast(max(Course_enrolments.mark)as integer), cast(round(median(Course_enrolments.mark))as integer),
cast(count(Course_enrolments.mark)as integer)
from Course_enrolments, Course_staff
where Course_staff.staff = $1
and Course_enrolments.course = Course_staff.course
and Course_enrolments.mark >= 0
group by Course_staff.course
;
return;
end;
$$ language plpgsql;




------



---
drop type if exists TeachingRecord cascade;
create type TeachingRecord as (cid integer, term char(4), code char(8), name text, uoc integer, average_mark integer, highest_mark integer, median_mark integer, totalEnrols integer);

create or replace function Q2(staff_id integer)
	returns setof TeachingRecord
as $$
declare result TeachingRecord;
BEGIN
if not exists(select * from staff where id = $1) then
  raise exception 'INVALID COURSEID';
else
return query
select distinct cast(Course_staff.course as integer), cast(lower(right(semesters.year::text, 2) || Semesters.term) as char(4)),
cast(Subjects.code as char(8)), cast(Subjects.name as text), cast(Subjects.uoc as integer),
cast(hm.average_mark as integer), cast(hm.highest_mark as integer), cast(hm.median_mark as integer), cast(hm.totalEnrols as integer)

from Course_staff, Semesters, Courses,Subjects,Q212($1) hm
where
    courses.id = hm.Cid
    and courses.semester = semesters.id
    and courses.subject = subjects.id
    and course_staff.course = courses.id
and hm.totalEnrols > 0
--group by Course_staff.course, semesters.year, Semesters.term, Subjects.code, Subjects.name,Subjects.uoc--,Course_enrolments.mark
;

return;
end if;
end;
--... SQL statements, possibly using other views/functions defined by you ...
$$ language plpgsql;




--Q3




drop type if exists f1 cascade;
create type f1 as (owner integer, member integer);

create or replace function Q31(org_id integer)
	returns setof f1
as $$
declare result f1;
begin
return query
select cast(OrgUnit_groups.owner as integer), cast(OrgUnit_groups.member as integer)
from OrgUnit_groups
where Orgunit_groups.owner = $1
;
return;
end;
$$ language plpgsql;



drop type if exists f22 cascade;
create type f22 as (unswid integer, student_name text);

create or replace function Q322(org_id integer, num_courses integer)
	returns setof f22
as $$
declare result f22;
begin
return query
select distinct cast(People.unswid as integer), cast(People.name as text)
from People, Subjects, Courses, Course_enrolments, Q31($1) f1
where Subjects.offeredBy = f1.member
and f1.owner = $1
and Subjects.id = Courses.subject
and Courses.id = Course_enrolments.Course
and Course_enrolments.student = People.id
group by People.unswid, People.name
having count(Courses.id ) > $2
;
return;
end;
$$ language plpgsql;



------

drop type if exists f66 cascade;
create type f66 as (unswid integer, student_name text);

create or replace function Q366(org_id integer, min_score integer)
	returns setof f66
as $$
declare result f66;
begin
return query
select distinct cast(People.unswid as integer), cast(People.name as text)
from People, Subjects, Courses, Course_enrolments, Q31($1) f1
where Subjects.offeredBy = f1.member
and f1.owner = $1
and Subjects.id = Courses.subject
and Courses.id = Course_enrolments.Course
and Course_enrolments.student = People.id
and Course_enrolments.mark >= $2
group by People.unswid, People.name
;
return;
end;
$$ language plpgsql;



drop type if exists CR cascade;
create type CR as (unswid integer, student_name text, course_records text, course_id integer, num bigint);

create or replace function Q388(org_id integer, num_courses integer, min_score integer)
  returns setof CR
as $$
declare result CR;
begin
return query
select cast(People.unswid as integer), cast(People.name as text),
cast(Subjects.code ||', '|| Subjects.name ||', '|| Semesters.name ||', '|| OrgUnits.name ||', '|| Course_enrolments.mark as text),
cast(Courses.id as integer),rank () over( partition by people.unswid order by  Course_enrolments.mark desc NULLS LAST) as rank
from People, Subjects, Semesters, Course_enrolments, OrgUnits, Courses, Q31($1) f1, Q366($1, $3) f2, Q322($1, $2) f3
where Subjects.offeredBy = f1.member
and People.unswid = f2.unswid
and People.unswid = f3.unswid
and Course_enrolments.student = People.id
and Course_enrolments.Course = Courses.id
and Courses.subject = Subjects.id
and Courses.semester = Semesters.id
and Subjects.offeredBy = OrgUnits.id
group by People.unswid, People.name, Subjects.code, Subjects.name, Semesters.name, OrgUnits.name, Course_enrolments.mark, Courses.id

order by people.unswid,Course_enrolments.mark desc NULLS LAST, Courses.id
;
return;
end;
$$ language plpgsql;



drop type if exists aaa cascade;
create type aaa as (unswid integer, student_name text, course_records text, course_id integer, num bigint);

  create or replace function Q31415926(org_id integer, num_courses integer, min_score integer)
    returns setof aaa
  as $$
  declare result aaa;
  BEGIN
  return query
  select * from Q388($1,$2,$3)
  where num<= 5;
  return;
  end;
  $$ language plpgsql;

----

drop type if exists CourseRecord cascade;
create type CourseRecord as (unswid integer, student_name text, course_records text);

create or replace function Q3(org_id integer, num_courses integer, min_score integer)
  returns setof CourseRecord
as $$
declare results CourseRecord;
begin
if not exists(select * from orgunits where orgunits.id=$1) then
raise exception 'INVALID ORGID';
end if;
return query
select cast(People.unswid as integer), cast(People.name as text),
concat(cast(course_records as text))
from People, Q31415926($1,$2,$3) f1
where f1.unswid = People.unswid
group by People.unswid, People.name
order by People.unswid
;
return;
end;
$$ language plpgsql;












-----

create or replace function
   appendNext(_state text, _next text) returns text
  as $$
  begin
   return _state||E'\n'||_next;
  end;
  $$ language plpgsql;

  create or replace function
   finalText(_final text) returns text
  as $$
  begin
   return substr(_final,2,length(_final)) || E'\n';
  end;
  $$ language plpgsql;

  create aggregate concat (text)
  (
   stype     = text,
   initcond  = '',
   sfunc     = appendNext,
   finalfunc = finalText
  );
