{#
    Cast a string column to a specific data type with NULL handling.
    
    This macro provides consistent type casting across staging models,
    handling empty strings and whitespace as NULL values.
    
    Usage:
        {{ safe_cast('price', 'decimal(10,2)') }}
        {{ safe_cast('quantity', 'int') }}
        {{ safe_cast('sales_date', 'timestamp') }}
    
    Args:
        column: The column name to cast
        data_type: The target data type (e.g., 'bigint', 'decimal(10,2)', 'timestamp')
#}

{% macro safe_cast(column, data_type) %}
    cast(nullif(trim({{ column }}), '') as {{ data_type }})
{% endmacro %}
