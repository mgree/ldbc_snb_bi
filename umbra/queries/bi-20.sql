/* Q20. Recruitment
\set person2Id 32985348834889
\set company 'Express_Air'
 */
with recursive
qs(f, t) as (
    select :person2Id, personid
    from Person_workat_company pwc, Company c
    where pwc.companyid = c.id and c.name=:company
),
path(src, dst, w) as (
    select p1.personid, p2.personid, min(abs(p1.classYear - p2.classYear)) + 1
    from Person_knows_person pp, Person_studyAt_University p1, Person_studyAt_University p2
    where pp.person1id = p1.personid and pp.person2id = p2.personid and p1.universityid = p2.universityid
    group by p1.personid, p2.personid
),
shorts(gsrc, dst, w, dead, iter) as (
    (
        with srcs as (select distinct f from qs)
        select f, f, 0, true, 0 from srcs
        union all
        select ss.f, p.dst, min(p.w), false, 0
        from srcs ss, path p
        where ss.f = p.src and p.dst not in (select ss2.f from srcs ss2)
        group by ss.f, p.dst
    )
    union all
    (
        with
        toExplore as (select * from shorts where dead = false order by w limit 1000),
        newPoints as (
            select e.gsrc as gsrc, p.dst as dst, min(e.w + p.w) as w, false as dead, min(e.iter) + 1 as iter
            from path p join toExplore e on forceorder(e.dst = p.src)
            group by e.gsrc, p.dst
        ),
        updated as (
            select n.gsrc, n.dst, n.w, false as dead, iter
            from newPoints n
            where not exists (select * from shorts o where n.gsrc = o.gsrc and n.dst = o.dst and o.w <= n.w)
        ),
        found as (
            select q.f, q.t, n.w
            from qs q left join updated n on n.dst = q.t and n.gsrc = q.f
        ),
        ss2 as (
            select o.gsrc, o.dst, o.w, o.dead or (exists (select * from toExplore e where e.gsrc = o.gsrc and e.dst = o.dst)) as dead, o.iter + 1 as iter
            from shorts o
        ),
        fullTable as (
            select coalesce(n.gsrc, o.gsrc) as gsrc,
                   coalesce(n.dst, o.dst) as dst,
                   coalesce(n.w, o.w) as w,
                   coalesce(n.dead, o.dead) as dead,
                   coalesce(n.iter, o.iter) as iter
            from ss2 o full join updated n on o.gsrc = n.gsrc and o.dst = n.dst
        )
        select gsrc,
               dst,
               w,
               dead or (t.w > coalesce((select min(w) from found f), t.w)),
               iter
        from fullTable t
        where exists (select * from toExplore limit 1)
    )
),
ss(gsrc, dst, w, iter) as (
    select gsrc, dst, w, iter from shorts where iter = (select max(iter) from shorts)
),
results(f, t, w) as (
    select qs.f, qs.t , ss.w from qs left join ss on qs.f = ss.gsrc and qs.t = ss.dst
)
select t, w from results where w = (select min(w) from results) order by t limit 20;
