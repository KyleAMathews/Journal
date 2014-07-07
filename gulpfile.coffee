gulp = require 'gulp'
gutil = require('gulp-util')
open = require 'open'
connect = require 'gulp-connect'
source = require('vinyl-source-stream')
watchify = require('watchify')

# Load plugins
$ = require('gulp-load-plugins')()

isProduction = process.env.NODE_ENV is "production"

# React code
gulp.task('scripts', ->
  return gulp.src('client.coffee', read: false)
    .pipe($.browserify({
      insertGlobals: true
      extensions: ['.cjsx', 'coffee']
      transform: 'coffee-reactify'
      debug: !isProduction
    }))
    .pipe($.if(isProduction, $.uglify()))
    .pipe($.rename('bundle.js'))
    .pipe(gulp.dest('public/'))
    .pipe($.size())
)

# CSS
gulp.task('css', ->
  gulp.src(['app/styles/main.sass'])
    .pipe($.compass({
      css: 'public/'
      sass: 'app/styles'
      image: 'app/styles/images'
      style: 'nested'
      comments: false
      bundle_exec: true
      time: true
      require: ['susy', 'modular-scale', 'normalize-scss',
        'sass-css-importer', 'breakpoint', 'sassy-buttons']
    }))
    .on('error', (err) ->
      console.log err
    )
    .pipe($.size())
    .pipe(connect.reload())
)

# Font compilation
gulp.task('font', $.shell.task([
  'fontcustom compile'
]))

# Connect
gulp.task 'connect', -> connect.server({
  root: ['public']
  port: 9000,
  livereload: true
})

gulp.task 'default', ->
  gulp.start 'build'

gulp.task 'build', ['scripts', 'css', 'font']

gulp.task 'watch', ['css', 'connect'], ->
  gulp.watch(['app/styles/**/*', 'app/react_components/**/*.scss'], ['css'])
  gulp.watch(['app/styles/icons/*'], ['font'])

  # https://github.com/gulpjs/gulp/blob/master/docs/recipes/fast-browserify-builds-with-watchify.md
  bundler = watchify('./app/bootstrap_and_router.cjsx', {
    extensions: ['.coffee', '.cjsx']
    'ignore-missing': true
  })
  bundler.transform('coffee-reactify')
  rebundle = ->
    return bundler.bundle({debug: !isProduction})
      .on("error", (err) ->
        gutil.log("Browserify error:", err)
      )
      .pipe(source('bundle.js'))
      .pipe(gulp.dest('./public'))
      .pipe($.connect.reload())

  bundler.on('update', rebundle)
  rebundle()
