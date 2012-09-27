if Rails.env == 'test' and File.exists?("config/api.test.yml")
  API_CONFIG = YAML.load_file(File.join(Rails.root, "config", "api.test.yml"))
elsif File.exists?("config/api.local.yml")
  API_CONFIG = YAML.load_file(File.join(Rails.root, "config", "api.local.yml"))
else
  API_CONFIG = YAML.load_file(File.join(Rails.root, "config", "api.yml"))
end