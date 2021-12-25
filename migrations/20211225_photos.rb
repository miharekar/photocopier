# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:photos) do
      primary_key :id
      String :file_name, null: false
      String :model, null: false
      DateTime :date_time_original_civil, null: false
      DateTime :imported_at
    end
  end
end
