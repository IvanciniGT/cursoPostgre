    SELECT
        pelicula,
        COUNT(*) AS num_visualizaciones
    FROM
        visualizaciones
    WHERE
        fecha >= CURRENT_DATE - INTERVAL '3 days'
    GROUP BY
        pelicula
    ORDER BY
        num_visualizaciones DESC
    LIMIT 30
