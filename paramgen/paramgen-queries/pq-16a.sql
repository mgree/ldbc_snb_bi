SELECT
    tagA AS 'tagA:STRING',
    dateA AS 'dateA:DATE',
    tagB AS 'tagB:STRING',
    dateB AS 'dateB:DATE',
    3 + (extract('dayofyear' FROM dateA)+extract('dayofyear' FROM dateB)) % 4 AS 'maxKnowsLimit:INT'
FROM (
    SELECT
        tagDatesA.tagName AS tagA,
        tagDatesA.creationDay AS dateA,
        tagDatesB.tagName AS tagB,
        tagDatesB.creationDay AS dateB
    FROM
        (SELECT
            max(creationDay) AS creationDay,
            tagName,
            frequency AS freq,
            abs(frequency - (SELECT percentile_disc(0.98) WITHIN GROUP (ORDER BY frequency) FROM creationDayAndTagNumMessages)) diff
         FROM creationDayAndTagNumMessages
         GROUP BY tagName, freq, diff
         ORDER BY diff, md5(tagName)
         LIMIT 100
        ) tagDatesA,
        (SELECT
            min(creationDay) AS creationDay,
            tagName,
            frequency AS freq,
            abs(frequency - (SELECT percentile_disc(0.97) WITHIN GROUP (ORDER BY frequency) FROM creationDayAndTagNumMessages)) diff
         FROM creationDayAndTagNumMessages
         GROUP BY tagName, freq, diff
         ORDER BY diff, md5(tagName)
         LIMIT 100
        ) tagDatesB
)
WHERE tagA <> tagB
ORDER BY md5(concat(tagA, tagB)), dateA, dateB
LIMIT 400