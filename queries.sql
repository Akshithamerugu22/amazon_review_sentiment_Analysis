CREATE DATABASE sentiment_analysis;
USE sentiment_analysis;
select * from cleaned_pipe;
#1. Total Number of Reviews
select count(*) as total_reviews from cleaned_pipe;

#2.Sentiment Distribution
select sentiment,count(sentiment) as total_reviews from cleaned_pipe 
Group by sentiment;

#3.Average Customer Rating
SELECT sentiment,ROUND(AVG(Score),2) AS average_rating
FROM cleaned_pipe
group by sentiment;

#4.Year-wise Review Count
select Year, count(*) as review_count from cleaned_pipe
group by year
order by year;

#5.Top 10 Most Reviewed Products
select productid,count(*) as total_review from cleaned_pipe
group by productid
order by total_review desc
limit 10;

#6Highest Rated Products
SELECT ProductId,
       ROUND(AVG(Score),2) AS average_rating,
       COUNT(*) AS review_count
FROM cleaned_pipe
GROUP BY ProductId
HAVING COUNT(*) >= 10
ORDER BY average_rating DESC
LIMIT 10;

#7.Highest Rated Year
SELECT Year,
       ROUND(AVG(Score),2) AS average_rating
FROM cleaned_pipe
GROUP BY Year
ORDER BY average_rating DESC;

#8.Products with the Most Negative Reviews 
SELECT ProductId,
       COUNT(*) AS negative_reviews
FROM cleaned_pipe
WHERE sentiment = 'Negative'
GROUP BY ProductId
ORDER BY negative_reviews DESC
LIMIT 10;

#9.Top Users Giving Positive Reviews 
SELECT UserId,
       COUNT(*) AS positive_reviews
FROM cleaned_pipe
WHERE sentiment = 'Positive'
GROUP BY UserId
ORDER BY positive_reviews DESC
LIMIT 10;