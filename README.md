# amazon_review_sentiment_Analysis
# Amazon Review Sentiment Analysis

End-to-end analytics project on Amazon Fine Food Reviews — from raw text to a trained sentiment classifier, SQL business analysis, and an interactive Power BI dashboard.

Pipeline:Data & EDA → NLP + ML → SQL Analysis → Power BI Dashboard

## Overview

Companies collect thousands of product reviews but can't read them all manually. This project automatically classifies each review as **Positive**, **Neutral**, or **Negative**, then answers business questions about which products, years, and users drive satisfaction or complaints — surfaced through a two-page interactive Power BI dashboard.

## Dataset

**Source:** Amazon Fine Food Reviews

| Metric | Value |
|---|---|
| Raw reviews loaded | 295,272 |
| Original columns | 10 |
| Duplicate review IDs | 0 |
| Review date range | 1999–2012 |
| Rows in Power BI dashboard sample | 6,262 (cleaned, pipe-delimited export) |

**Core fields:**

| Field | Description |
|---|---|
| `ProductId` / `UserId` | Grouping dimensions for rankings |
| `Score` (1–5) | Star rating — basis for the sentiment label |
| `Summary` / `Text` | Review title and full body — source for NLP |
| `Time` | Unix timestamp → converted to `Year` |
| `HelpfulnessNumerator` / `HelpfulnessDenominator` | "Was this helpful" vote counts |
| `sentiment` (derived) | Positive / Neutral / Negative label |

## Project Structure

```
├── social_media_sentiment_analysis.ipynb   # Full EDA, NLP, and model training notebook
├── cleaned_pipe.csv                        # Cleaned, pipe-delimited dataset used for SQL + Power BI
├── queries.sql                             # 9 business-question SQL queries
├── dashboard.pbix                          # Power BI dashboard (Overview )
└── README.md
```

## 1. Data Cleaning & EDA

Performed in `social_media_sentiment_analysis.ipynb` using Pandas, NumPy, Matplotlib, and Seaborn:

1. Checked and dropped missing values (nulls in `Summary`/`ProfileName`)
2. Verified no duplicate review IDs; confirmed row uniqueness
3. Removed inconsistent rows where `HelpfulnessNumerator > HelpfulnessDenominator`
4. Converted `Time` from Unix timestamp to datetime, extracted `Year`
5. Stripped whitespace from `Text`/`Summary`/`ProfileName`; dropped empty review text
6. Engineered `Review_Length`; explored rating distribution and average score by year

## 2. Sentiment Labeling

A rule-based label was derived directly from the star rating:

```python
def sentiment(score):
    if score >= 4:
        return 'Positive'
    elif score == 3:
        return 'Neutral'
    else:
        return 'Negative'

df['sentiment'] = df['Score'].apply(sentiment)
```

This label is the **ground truth** used both for the SQL/dashboard analysis and as the target the ML model later learns to predict from text alone.

**Class distribution (295,244 labeled reviews):**

| Sentiment | Count | Share |
|---|---|---|
| Positive | 229,361 | 77.7% |
| Negative | 43,047 | 14.6% |
| Neutral | 22,836 | 7.7% |

> The dataset is strongly imbalanced toward Positive — this shapes both the model's behavior and the interpretation of its results (see [Limitations](#limitations--future-work)).

## 3. Text Preprocessing (NLP)

Using NLTK, each review's `Text` was cleaned through:

1. **Lowercase** all characters
2. **Strip HTML tags and URLs** via regex
3. **Remove punctuation & special characters** — keep only alphabetic characters
4. **Tokenize** into individual words
5. **Remove stopwords** (common low-signal words like "the", "is")
6. **Lemmatize** each token to its root form (e.g., "running" → "run")

## 4. Feature Engineering — TF-IDF

Cleaned, tokenized text was converted into numeric vectors using TF-IDF (Term Frequency–Inverse Document Frequency):

```python
from sklearn.feature_extraction.text import TfidfVectorizer

tfidf = TfidfVectorizer()
X = tfidf.fit_transform(df['Processed_Text'])
```

TF-IDF down-weights common words that appear in almost every review and up-weights distinctive words that carry real sentiment signal, producing a sparse matrix that scales well to hundreds of thousands of reviews.

## 5. Model — Logistic Regression

**Setup:**
- 80/20 train-test split (`random_state=42`)
- Input: TF-IDF vectors | Target: `sentiment`
- `LogisticRegression(max_iter=1000)`
- Test set: 59,049 reviews

**Results:**

| Metric | Value |
|---|---|
| **Overall accuracy** | **86.8%** |

| Class | Precision | Recall | F1-score |
|---|---|---|---|
| Positive | 0.89 | 0.97 | 0.93 |
| Negative | 0.76 | 0.67 | 0.71 |
| Neutral | 0.56 | 0.20 | 0.30 |

The model mirrors the dataset's class imbalance: it predicts Positive reviews very reliably, but Neutral reviews — the smallest and least linguistically distinct class — are the hardest to catch.

## 6. SQL Analysis

Nine business questions answered directly against `cleaned_pipe.csv` (see [`queries.sql`](queries.sql)):

1. Total review volume
2. Sentiment distribution
3. Average rating by sentiment
4. Year-wise review count
5. Top 10 most-reviewed products
6. Highest-rated products (≥10 reviews)
7. Highest-rated year
8. Products with the most negative reviews
9. Top users giving positive reviews

These queries are the direct source for every KPI and chart in the Power BI dashboard.

## 7. Power BI Dashboard

Two-page interactive report (`dashboard.pbix`):

**Page  — Overview**
- Slicers: Year, Sentiment, Score, Product ID
- KPI cards: Total Reviews, Average Rating, % Positive, % Negative
- Sentiment distribution donut, year-wise review trend line
- Top 10 most-reviewed products, highest-rated products table, most-negative-reviews chart, top positive-review users table

## Key Insights

- Nearly 4 in 5 reviews are positive (77.7%) — overall sentiment skews strongly favorable
- Negative reviews (14.6%) still represent tens of thousands of reviews worth investigating per product
- A small number of products account for a disproportionate share of negative feedback — clear targets for quality review
- The Logistic Regression model reaches 86.8% accuracy, reliable enough to automate first-pass sentiment tagging at scale
- Neutral reviews are the hardest to classify — both for the model and for a quick human read

## Tech Stack

| Layer | Tools |
|---|---|
| Data cleaning & EDA | Python — Pandas, NumPy, Matplotlib, Seaborn |
| NLP preprocessing | NLTK (tokenization, stopwords, lemmatization) |
| Modeling | scikit-learn — TF-IDF, Logistic Regression |
| Business analysis | MySQL |
| Visualization | Power BI (DAX, slicers, drill-through) |

## How to Run

**1. Notebook (data cleaning, NLP, model training)**
```bash
pip install pandas numpy matplotlib seaborn nltk scikit-learn
jupyter notebook social_media_sentiment_analysis.ipynb
```

**2. SQL analysis**
```bash
mysql -u <user> -p < queries.sql
```
Load `cleaned_pipe.csv` into the `cleaned_pipe` table first (pipe-delimited, `|`).

**3. Power BI dashboard**

Open `dashboard.pbix` in Power BI Desktop. If rebuilding from scratch, import `cleaned_pipe.csv` with `|` as the custom delimiter.

## Limitations & Future Work

- **Class imbalance** (77.7% Positive) biases the model toward predicting Positive
- **Neutral reviews** use mixed or subtle language, closer to a "3-star — it's OK" tone — hard to separate linguistically
- **TF-IDF + Logistic Regression** is fast and interpretable, but ignores word order and context

**Next steps:**
- Address imbalance with class weighting, oversampling (SMOTE), or undersampling
- Try richer embeddings (word2vec, or a fine-tuned transformer like BERT) to capture context
- Track macro F1 or a confusion-matrix-aware metric, not just accuracy, given the imbalance

---

*Built as an end-to-end demonstration of the full analytics lifecycle: data cleaning → NLP → machine learning → SQL → BI dashboarding.*
