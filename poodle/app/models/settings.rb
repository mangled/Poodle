# See: http://github.com/binarylogic/settingslogic and the associated yml file
class Settings < Settingslogic
  source "#{Rails.root}/config/application.yml"
  namespace Rails.env
end
