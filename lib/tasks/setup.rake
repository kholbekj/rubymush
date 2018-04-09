desc 'Create db and seed basic room.'
task setup: [ 'db:create', 'db:schema:load', 'db:seed' ] do
  puts 'Setup completed.'
end
