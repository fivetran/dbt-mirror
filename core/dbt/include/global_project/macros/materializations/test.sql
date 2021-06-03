{%- materialization test, default -%}

  {% set relations = [] %}

  {% if should_store_failures() %}

    {% set identifier = model['alias'] %}
    {% set old_relation = adapter.get_relation(database=database, schema=schema, identifier=identifier) %}
    {% set target_relation = api.Relation.create(
        identifier=identifier, schema=schema, database=database, type='table') -%} %}
    
    {% if old_relation %}
        {% do adapter.drop_relation(old_relation) %}
    {% endif %}
    
    {% call statement(auto_begin=True) %}
        {{ create_table_as(False, target_relation, sql) }}
    {% endcall %}
    
    {% do relations.append(target_relation) %}
  
    {% set main_sql %}
        select *
        from {{ target_relation }}
    {% endset %}
    
    {{ adapter.commit() }}
  
  {% else %}

      {% set main_sql %}
          select *
          from (
            {{ sql }}
          ) dbt_internal_test
      {% endset %}
  
  {% endif %}

  {% set limit = config.get('limit') %}
  {% set fail_calc = config.get('fail_calc') %}
  {% set warn_if = config.get('warn_if') %}
  {% set error_if = config.get('error_if') %}

  {% call statement('main', fetch_result=True) -%}

    select
      {{ fail_calc }} as failures,
      {{ fail_calc }} {{ warn_if }} as should_warn,
      {{ fail_calc }} {{ error_if }} as should_error
    from (
      {{ main_sql }}
      {{ "limit " ~ limit if limit != none }}
    ) dbt_internal_test

  {%- endcall %}
  
  {{ return({'relations': relations}) }}

{%- endmaterialization -%}