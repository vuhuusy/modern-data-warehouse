{#
    Generate a surrogate key by hashing one or more columns.
    
    This macro creates a deterministic hash-based surrogate key from
    the provided columns, suitable for dimension tables.
    
    Usage:
        {{ generate_surrogate_key(['customer_id', 'product_id']) }}
    
    Output:
        to_hex(md5(to_utf8(coalesce(cast(customer_id as varchar), '_null_') || '|' || coalesce(cast(product_id as varchar), '_null_'))))
    
    Args:
        columns: List of column names to include in the surrogate key
        null_placeholder: String to use for NULL values (default: '_null_')
        separator: String to separate column values (default: '|')
#}

{% macro generate_surrogate_key(columns, null_placeholder='_null_', separator='|') %}
    {% set formatted_columns = [] %}
    {% for column in columns %}
        {% do formatted_columns.append("coalesce(cast(" ~ column ~ " as varchar), '" ~ null_placeholder ~ "')") %}
    {% endfor %}
    to_hex(md5(to_utf8({{ formatted_columns | join(" || '" ~ separator ~ "' || ") }})))
{% endmacro %}
