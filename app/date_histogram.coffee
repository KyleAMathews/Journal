d3 = require 'd3'

module.exports = (options) ->
  # Formatters for counts and times (converting numbers to Dates).
  formatCount = d3.format(",.0f")
  formatTime = d3.time.format("%b %y")
  formatDate = (d) ->
    formatTime new Date(d)

  margin =
    top: 26
    right: 13
    bottom: 19.5
    left: 13

  width = options.containerWidth - 25
  height = 81.5
  ticks = Math.round(options.containerWidth/36)

  x = x = d3.time.scale.utc()
    #.domain([0, 120])
    .domain(d3.extent(options.values))
    .range([0, width])
    .nice(ticks)

  # Generate a histogram using 20 uniformly-spaced bins.
  data = data = d3.layout.histogram()
    .bins(x.ticks(ticks))(options.values)

  y = y = d3.scale.linear()
      .domain([0, d3.max(data, (d) -> d.y)])
      .range([height, 0])

  xAxis = d3.svg.axis()
    .scale(x)
    .orient("bottom")
    .tickFormat(formatDate)

  svg = d3.select(options.selector)
    .append("svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom)
    .append("g")
    .attr("transform", "translate(" + margin.left + "," + margin.top + ")")

  bar = svg.selectAll(".bar")
    .data(data)
    .enter()
    .append("g")
    .attr("class", "bar")
    .attr("transform", (d) ->
      "translate(" + x(d.x) + "," + y(d.y) + ")"
    )

  bar.append("rect")
    .attr("x", 1)
    .attr("width", width/data.length - 3.25)
    #.attr("width", 19)
    .attr "height", (d) ->
      height - y(d.y)

  bar.append("text")
    .attr("dy", ".75em")
    .attr("y", 6)
    .attr("x", (width/data.length - 3.25) / 2)
    .attr("text-anchor", "middle")
    .text (d) ->
      formatCount d.y

  svg.append("g")
    .attr("class", "x axis")
    .attr("transform", "translate(0," + height + ")")
    .call xAxis
