ActiveRecord::Base.establish_connection(adapter: 'postgresql', database: 'returning_attributes')
ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Schema.define do
  enable_extension 'uuid-ossp'

  create_table :projects, force: true do |t|
    t.string :name
    t.uuid :uuid, default: -> { 'uuid_generate_v4()' }
    t.integer :update_count, default: 0
  end

  execute(<<~EOSQL)
    CREATE OR REPLACE FUNCTION increment_update_count()
    RETURNS TRIGGER AS $$
    BEGIN
        NEW.update_count = OLD.update_count + 1;
        RETURN NEW;
    END;
    $$ language 'plpgsql';

    DROP TRIGGER IF EXISTS increment_project_update_count_on_update ON projects;
    CREATE TRIGGER increment_project_update_count_on_update BEFORE UPDATE ON projects FOR EACH ROW EXECUTE PROCEDURE increment_update_count();
  EOSQL
end

Project = Class.new(ActiveRecord::Base)
