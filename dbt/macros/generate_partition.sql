{#
    Generate partition column value from a date/timestamp column.
    
    Usage:
        {{ generate_partition('sales_at') }}
    
    Output:
        date_format(sales_at, '%Y%m%d') as partition
    
    Args:
        date_column: The name of the date/timestamp column to derive partition from
        alias: Optional alias for the partition column (default: 'partition')
#}

{% macro generate_partition(date_column, alias='partition') %}
    date_format({{ date_column }}, '%Y%m%d') as {{ alias }}
{% endmacro %}
