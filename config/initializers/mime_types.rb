# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
# Mime::Type.register "application/x-mobile", :mobile
# Image formats
Mime::Type.register "image/jpg", :jpg
Mime::Type.register "image/gif", :gif
Mime::Type.register "image/png", :png
# Movie formats
Mime::Type.register "video/quicktime", :mov
Mime::Type.register "video/quicktime", :qt
# Application formats
Mime::Type.register "application/pdf", :pdf
# Export formats
Mime::Type.register "text/plain", :dp