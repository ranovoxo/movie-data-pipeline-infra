import pg from "pg";

const { Pool } = pg;

let pool;

const demo = {
  topMovies: [],
  ratingsByLanguage: [],
  yearlyCounts: [],
  genrePredictions: [],
  summary: {
    total_movies: 0,
    total_languages: 0,
    latest_release_year: null,
    top_movie: "Unavailable",
    top_weighted_score: 0,
    prediction_accuracy: null,
    latest_etl_run: null,
    source: "postgres"
  }
};

const headers = {
  "content-type": "application/json",
  "access-control-allow-origin": process.env.CORS_ALLOW_ORIGIN || "*",
  "access-control-allow-methods": "GET,OPTIONS",
  "access-control-allow-headers": "content-type"
};

function response(statusCode, body) {
  return {
    statusCode,
    headers,
    body: JSON.stringify(body)
  };
}

function connectionStringWithoutSslMode(connectionString) {
  const url = new URL(connectionString);
  url.searchParams.delete("sslmode");
  return url.toString();
}

function getPool() {
  if (!process.env.DATABASE_URL) {
    throw new Error("DATABASE_URL is not configured");
  }

  if (!pool) {
    pool = new Pool({
      connectionString: connectionStringWithoutSslMode(process.env.DATABASE_URL),
      ssl: process.env.PGSSL === "false" ? false : { rejectUnauthorized: false },
      max: Number(process.env.PGPOOL_MAX || 2),
      idleTimeoutMillis: 30_000,
      connectionTimeoutMillis: 10_000
    });
  }

  return pool;
}

function numberValue(value, fallback = 0) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function integerValue(value) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? Math.round(parsed) : null;
}

async function query(sql) {
  const result = await getPool().query(sql);
  return result.rows;
}

async function topMovies() {
  const rows = await query(`
    select
      title,
      nullif(split_part(release_date, '-', 1), '')::int as release_year,
      vote_average,
      vote_count,
      weighted_score,
      original_language
    from gold_top_movies
    order by weighted_score desc nulls last
    limit 12
  `);

  return rows.map((row) => ({
    title: String(row.title ?? "Untitled"),
    release_year: integerValue(row.release_year),
    vote_average: numberValue(row.vote_average),
    vote_count: numberValue(row.vote_count),
    weighted_score: numberValue(row.weighted_score),
    original_language: row.original_language ? String(row.original_language) : null
  }));
}

async function ratingsByLanguage() {
  const rows = await query(`
    select
      ratings.language as original_language,
      ratings.avg_vote as avg_rating,
      coalesce(language_counts.movie_count, 0)::int as movie_count
    from gold_avg_rating_by_language ratings
    left join (
      select original_language, count(*)::int as movie_count
      from movies_silver
      group by original_language
    ) language_counts
      on language_counts.original_language = ratings.language
    order by ratings.avg_vote desc nulls last
    limit 12
  `);

  return rows.map((row) => ({
    original_language: String(row.original_language ?? "unknown"),
    avg_rating: numberValue(row.avg_rating),
    movie_count: numberValue(row.movie_count)
  }));
}

async function yearlyCounts() {
  const rows = await query(`
    select
      year::int as release_year,
      count::int as movie_count
    from gold_yearly_counts
    where year is not null
    order by year asc
  `);

  return rows.map((row) => ({
    release_year: numberValue(row.release_year),
    movie_count: numberValue(row.movie_count)
  }));
}

async function mlTableExists() {
  const rows = await query("select to_regclass('public.ml_genre_predictions') is not null as exists");
  return Boolean(rows[0]?.exists);
}

async function genrePredictions() {
  if (!(await mlTableExists())) {
    return [];
  }

  const rows = await query(`
    select
      movie_id,
      title,
      actual_genre,
      predicted_genre,
      confidence
    from ml_genre_predictions
    order by movie_id desc nulls last
    limit 50
  `);

  return rows.map((row) => ({
    movie_id: integerValue(row.movie_id),
    title: String(row.title ?? "Untitled"),
    actual_genre: row.actual_genre ? String(row.actual_genre) : null,
    predicted_genre: row.predicted_genre ? String(row.predicted_genre) : null,
    confidence: row.confidence == null ? null : numberValue(row.confidence)
  }));
}

async function summary() {
  const rows = await query(`
    with movie_stats as (
      select
        count(*)::int as total_movies,
        count(distinct original_language)::int as total_languages,
        max(nullif(split_part(release_date, '-', 1), '')::int) as latest_release_year
      from movies_silver
    ),
    top_movie as (
      select title, weighted_score
      from gold_top_movies
      order by weighted_score desc nulls last
      limit 1
    )
    select
      movie_stats.total_movies,
      movie_stats.total_languages,
      movie_stats.latest_release_year,
      top_movie.title as top_movie,
      top_movie.weighted_score as top_weighted_score
    from movie_stats
    cross join top_movie
  `);

  const row = rows[0] ?? {};
  let predictionAccuracy = null;

  if (await mlTableExists()) {
    const accuracyRows = await query(`
      select
        case
          when count(*) = 0 then null
          else avg((actual_genre = predicted_genre)::int)::float
        end as prediction_accuracy
      from ml_genre_predictions
    `);
    predictionAccuracy = accuracyRows[0]?.prediction_accuracy == null ? null : numberValue(accuracyRows[0].prediction_accuracy);
  }

  return {
    total_movies: numberValue(row.total_movies),
    total_languages: numberValue(row.total_languages),
    latest_release_year: integerValue(row.latest_release_year),
    top_movie: String(row.top_movie ?? "Unavailable"),
    top_weighted_score: numberValue(row.top_weighted_score),
    prediction_accuracy: predictionAccuracy,
    latest_etl_run: null,
    source: "postgres"
  };
}

async function route(path) {
  const normalized = path.replace(/^\/+/, "");

  switch (normalized) {
    case "api/reports/top-movies":
    case "reports/top-movies":
      return topMovies();
    case "api/reports/ratings-by-language":
    case "reports/ratings-by-language":
      return ratingsByLanguage();
    case "api/reports/yearly-counts":
    case "reports/yearly-counts":
      return yearlyCounts();
    case "api/reports/genre-predictions":
    case "reports/genre-predictions":
      return genrePredictions();
    case "api/reports/summary":
    case "reports/summary":
      return summary();
    default:
      return null;
  }
}

export async function handler(event) {
  if (event.requestContext?.http?.method === "OPTIONS") {
    return response(204, {});
  }

  try {
    const payload = await route(event.rawPath || event.path || "");

    if (payload == null) {
      return response(404, { error: "Not found" });
    }

    return response(200, payload);
  } catch (error) {
    console.error("reports-api error", error);

    return response(500, {
      error: "Report query failed",
      source: "postgres"
    });
  }
}
