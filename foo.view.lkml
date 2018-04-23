view: foo {
  sql_table_name: public.foo ;;

  dimension: i {
    type: number
    sql: ${TABLE}.i ;;
  }

  measure: count {
    type: count
    drill_fields: []
  }
}
