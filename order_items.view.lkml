view: order_items {
  sql_table_name: public.order_items ;;


  dimension: id {
    primary_key: yes
    type: number
    sql: ${TABLE}.id ;;
  }

  dimension_group: created {
    type: time
    timeframes: [
      raw,
      time,
      date,
      week,
      month,
      quarter,
      year
    ]
    sql: ${TABLE}.created_at ;;
    convert_tz: no
  }

  dimension_group: delivered {
    type: time
    timeframes: [
      raw,
      time,
      date,
      week,
      month,
      quarter,
      year
    ]
    sql: ${TABLE}.delivered_at ;;
  }

  dimension: inventory_item_id {
    type: number
    # hidden: yes
    sql: ${TABLE}.inventory_item_id ;;
  }

  dimension: order_id {
    type: number
    sql: ${TABLE}.order_id ;;
  }

  dimension_group: returned {
    type: time
    timeframes: [
      raw,
      time,
      date,
      week,
      month,
      quarter,
      year
    ]
    sql: ${TABLE}.returned_at ;;
  }

  dimension: sale_price {
    type: number
    value_format_name: eur
    sql: ${TABLE}.sale_price ;;
  }

  dimension_group: shipped {
    type: time
    timeframes: [
      raw,
      time,
      date,
      week,
      month,
      quarter,
      year
    ]
    sql: ${TABLE}.shipped_at ;;
  }

  dimension: status {
    type: string
    sql: ${TABLE}.status ;;
  }

  dimension: user_id {
    type: number
    # hidden: yes
    sql: ${TABLE}.user_id ;;
  }

  measure: count {
    type: count
    drill_fields: [detail*]
  }

#///////////////////////////////////////////////////////////////////////////////////////
# MY MEASURES
#///////////////////////////////////////////////////////////////////////////////////////

# items_sold
measure: my_Items_Sold {            #TESTED#
  type: count_distinct
  sql: ${inventory_item_id} ;;
}
# count distinct of customers
measure: my_Total_customers{        #TESTED#
  type: count_distinct
  sql: ${user_id} ;;
}


# ---------------------------------------------------------------------------------------
# Revenue Measures

# Total Sale Price - Total sales from items sold
measure: my_Total_Sale_Price {      #TESTED#
      type: sum
    value_format_name: eur
    sql: ${sale_price} ;;
  }

# Average Sale Price - Average sale price of items sold
measure:  my_Average_Sale_Price{    #TESTED#
  type:  average
  value_format_name: eur
  sql: ${sale_price} ;;
}

# Cumulative Total Sales - Cumulative total sales from items sold (also known as a running total)
  # Running total needs to be built on a measure.
measure: my_Cumulative_Total_Sales{   #TESTED#
  type: running_total
  value_format_name: eur
  sql:  ${my_Total_Sale_Price} ;;
}

# Total Gross Revenue - Total revenue from completed sales (cancelled and returned orders excluded)
measure: my_Gross_Revenue{          #TESTED#
  type: sum
  value_format_name: eur
  sql: ${sale_price};;
  filters: {
    field: order_items.status
    value: "Complete"         # Minus sign means "not"
  }
}

# Total Gross Margin Amount - Total difference between the total revenue from COMPLETED sales
# and the cost of the goods that were sold
measure: my_Total_Gross_Margin {    #TESTED#
    type: sum
    value_format_name: eur
    sql:  ${sale_price} - ${products.cost}  ;;
    filters: {
      field: order_items.status
      value: "Complete"
    }
  }
    # Total Cost of all items sold = Cost * Number of Items sold
    measure: my_Total_Product_Cost{ #TESTED#
      type: sum
      value_format_name: eur
      sql: ${products.cost}  ;;
    }

# Average Gross Margin - Average difference between the total revenue from COMPLETED
# sales and the cost of the goods that were sold
measure: my_Average_Gross_Margin {  #TESTED#
  type: average
  value_format_name: eur
  sql:  ${sale_price} - ${products.cost}  ;;
  filters: {
    field: order_items.status
    value: "Complete"
  }
}

# Gross Margin % - Total Gross Margin Amount / Total Revenue
  measure: my_Gross_Margin_Percent {    #TESTED#
    type: average
    value_format_name:percent_2
    # sql:  (${sale_price} - ${products.cost}) / ${sale_price} ;;
    sql:  (1.0*${sale_price} - ${products.cost}) / NULLIF(${sale_price},0) ;;
    filters: {
      field: order_items.status
      value: "Complete"
    }
}

# Average Spend per Customer - Total Sale Price / total number of customers
  measure: my_ARPU {                    #TESTED#
    type: number
    value_format_name: eur
    sql: 1.0 * ${my_Total_Sale_Price} / NULLIF(${my_Total_customers},0) ;;
  }

# ---------------------------------------------------------------------------------------
# Returned Items Measures

# Number of Items Returned - Number of items that were returned by dissatisfied customers
measure: my_Items_Returned {            #TESTED#
  type: count_distinct
  sql: ${order_id} ;;
  filters: {
    field: status
    value: "Returned"
  }
}

# Item Return Rate - Number of Items Returned / total number of items sold
measure: my_Item_Return_Rate{           #TESTED#
  type: number
  value_format_name:percent_2
  sql: 1.0*${my_Items_Returned} / nullif(${my_Items_Sold},0) ;;
    # For percentages, *1.0 to get a float and then us nulliff to avoid devide by 0
}

# Number of Customers Returning Items - Number of users who have returned an item at some point
measure: my_Customers_Returning_Items {  #TESTED#
  type: count_distinct
  sql:  ${user_id};;
  filters: {
    field: order_items.status
    value: "Returned"
  }
}

# % of Users with Returns - Number of Customer Returning Items / total number of customers
measure: my_Users_With_Returns_percent {  #TESTED#
  type: number
  value_format_name: percent_2
  sql: 1.0*${my_Customers_Returning_Items} / nullif(${my_Total_customers},0) ;;
    # For percentages, *1.0 to get a float and then us nulliff to avoid devide by 0
}


# ---------------------------------------------------------------------------------------
# Drilldowns
  # ----- Sets of fields for drilling ------
  set: detail {
    fields: [
      id,
      users.id,
      users.first_name,
      users.last_name,
      inventory_items.id,
      inventory_items.product_name
    ]
  }
}
