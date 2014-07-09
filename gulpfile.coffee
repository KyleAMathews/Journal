gulp = require 'gulp'
gutil = require('gulp-util')
open = require 'open'
connect = require 'gulp-connect'
source = require('vinyl-source-stream')
watchify = require('watchify')
browserify = require 'browserify'

# Load plugins
$ = require('gulp-load-plugins')()

isProduction = process.env.NODE_ENV is "production"

# React code
gulp.task('scripts', ->
  bundler = browserify('./app/bootstrap_and_router.cjsx', {
    extensions: ['.cjsx', '.coffee']
    'ignore-missing': true
  })
  bundler.transform('coffee-reactify')
  bundler.bundle({
    debug: !isProduction
  })
  .pipe($.plumber())
  .on('error', $.notify.onError (error) -> return error.message)
  .pipe(source('bundle.js'))
  .pipe($.if(isProduction, $.streamify($.uglify())))
  .pipe(gulp.dest('./public'))
)

# CSS
gulp.task('css', ->
  gulp.src(['app/styles/main.sass'])
    .pipe($.plumber())
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
    .on('error', $.notify.onError (error) -> return error.message)
    .pipe($.size())
    .pipe(connect.reload())
)

# Font compilation
gulp.task('font', $.shell.task([
  'fontcustom compile'
]))

gulp.task('font-base-64', ->
  gulp.src('assets/fonts/*.ttf')
    .pipe($.rename('fontcustom.ttf'))
    .pipe($.cssfont64())
    .pipe($.rename('_fontcustom_embedded.scss'))
    .pipe(gulp.dest('app/styles/'))
)

gulp.task('copy-assets', ->
  gulp.src('assets/**')
    .pipe(gulp.dest('public'))
    .pipe($.size())
)

# Connect
gulp.task 'connect', -> connect.server({
  root: ['public']
  port: 9000,
  livereload: true
})

gulp.task 'default', ->
  gulp.start 'build'

gulp.task 'build', ['scripts', 'font', 'font-base-64', 'css', 'copy-assets']

gulp.task 'watch', ['css', 'connect'], ->
  gulp.watch(['app/styles/**/*', 'app/react_components/**/*.scss'], ['css'])
  gulp.watch(['app/styles/icons/*'], ['font'])
  gulp.watch(['assets/**'], ['copy-assets'])

  # Run watchify for fast browserify rebuilds.
  bundler = watchify('./app/bootstrap_and_router.cjsx', {
    extensions: ['.coffee', '.cjsx']
    'ignore-missing': true
  })
  bundler.transform('coffee-reactify')
  rebundle = ->
    return bundler.bundle({debug: !isProduction})
      .pipe($.plumber())
      .on('error', $.notify.onError (error) -> return error.message)
      .pipe(source('bundle.js'))
      .pipe(gulp.dest('./public'))
      .pipe($.connect.reload())

  bundler.on('update', rebundle)
  rebundle()
