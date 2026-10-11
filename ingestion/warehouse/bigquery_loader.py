#cargamos los json de google cloud storage a bigquery

from google.cloud import bigquery

client = bigquery.Client()

def bigquery_load_from_gcs(uri: str, table_id:str): #uri es el enlace del ndjson en gcs, table_id es la tabla donde se va a subir en bigquery
    # table_id = "your-project.your_dataset.your_table_name
    job_config = bigquery.LoadJobConfig( 
        autodetect=True, #schema del json
        source_format=bigquery.SourceFormat.NEWLINE_DELIMITED_JSON,
        write_disposition=bigquery.WriteDisposition.WRITE_APPEND #sirve para que la tabla no se reescriba, si no que se agregue
    )

    load_job = client.load_table_from_uri(uri, table_id, job_config=job_config)

    return load_job.result()

def bigquery_delete_snapshot_date(table_id:str, snapshot_date_delete:str): #table_id, la tabla de donde se va a borrar la fecha, snapshot_date_delete, fecha (garantizar solo 100 en un día)
    param = bigquery.ScalarQueryParameter("snapshot_date", "DATE", snapshot_date_delete) #nombre, tipo de dato, valor asignado

    job_config = bigquery.QueryJobConfig(
        query_parameters=[param] #se le pasan los parametros definidos
    )

    query = f"""DELETE FROM `{table_id}`
    WHERE snapshot_date = @snapshot_date""" #query @sirve para llamar una variable definida con ScalarQueryParameter, `` sirven para nombres de tabla

    query_job = client.query(query, job_config=job_config) #le pasamos la query el jobconfig con los parametros para la query
    query_job.result() #necesario para ver el numero de filas borradas

    print("Filas borradas:", query_job.num_dml_affected_rows)


    


