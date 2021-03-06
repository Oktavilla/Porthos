Porthos.namespace('Porthos.Editor');
if (typeof Porthos.jQuery == "undefined") {
  Porthos.jQuery = jQuery.noConflict();
}
if (typeof Porthos.Editor.Options == "undefined") {
  Porthos.Editor.Options = {};
}

Object.extend(Porthos.Editor.Options, {
  updateSelector: ".commit",

  updateEvent: "click",
  
  skin: "porthos",

  //options
  dialogFeatures: "menubar=yes,titlebar=no,toolbar=no,resizable=yes,scrollbars=yes,width=870,height=820,top=0,left=0",

  lang: "sv",

  //classes panel
  classesItems: [
    { 'name': 'preamble', 'title': 'P: Ingress', 'expr': 'p' }
  ],

  //editor css values for visual feedback
  editorStyles: [
    { 'name': '.preamble', 'css': 'font-weight:bold;' }
  ],

  //dialogs css values
  dialogStyles: [
    { 'name': '.preamble', 'css': 'font-weight:bold;' }
  ],

  toolsItems: [
    { 'name': 'Bold',                 'title': 'Strong',            'css': 'wym_tools_strong'          },
    { 'name': 'Italic',               'title': 'Emphasis',          'css': 'wym_tools_emphasis'        },
    { 'name': 'Superscript',          'title': 'Superscript',       'css': 'wym_tools_superscript'     },
    { 'name': 'Subscript',            'title': 'Subscript',         'css': 'wym_tools_subscript'       },
    { 'name': 'InsertOrderedList',    'title': 'Ordered_List',      'css': 'wym_tools_ordered_list'    },
    { 'name': 'InsertUnorderedList',  'title': 'Unordered_List',    'css': 'wym_tools_unordered_list'  },
    { 'name': 'Indent',               'title': 'Indent',            'css': 'wym_tools_indent'          },
    { 'name': 'Outdent',              'title': 'Outdent',           'css': 'wym_tools_outdent'         },
    { 'name': 'Undo',                 'title': 'Undo',              'css': 'wym_tools_undo'            },
    { 'name': 'Redo',                 'title': 'Redo',              'css': 'wym_tools_redo'            },
    { 'name': 'CreateLink',           'title': 'Link',              'css': 'wym_tools_link'            },
    { 'name': 'Unlink',               'title': 'Unlink',            'css': 'wym_tools_unlink'          },
    { 'name': 'InsertTable',          'title': 'Table',             'css': 'wym_tools_table'           },
    { 'name': 'Paste',                'title': 'Paste_From_Word',   'css': 'wym_tools_paste'           },
    { 'name': 'ToggleHtml',           'title': 'HTML',              'css': 'wym_tools_html'            },
    { 'name': 'Preview',              'title': 'Preview',           'css': 'wym_tools_preview'         }
  ],
      dialogLinkHtml:  "<body class='wym_dialog wym_dialog_link A'"
                       + " onload='WYMeditor.INIT_DIALOG(" + WYMeditor.INDEX + ")'"
                       + ">"
                       + "<div class='dialog_content'>"
                       + "  <h1>Skapa en länk</h1>"
                       + "  <div class='column column1'><div class='inner'>"
                       + "    <form>"
                       + "<input type='hidden' class='wym_dialog_type' value='"
                       + WYMeditor.DIALOG_LINK
                       + "' />"
                       + "      <label>Länk</label>"
                       + "      <input type='text' class='wym_href' value='' size='60' />"
                       + "      <span class='form_help'>Glöm inte http:// om du länkar till andra webbplatser</span>"
                       + "      <label>Titel</label>"
                       + "      <input type='text' class='wym_title' value='' size='60' />"
                       + "      <span class='form_help'>Syns när besökaren håller pekaren över länken</span>"
                       + "      <div class='submit absolute'>"
                       + "        <input class='wym_submit' type='button' value='Lägg in länk' /> eller <a href='#' class='wym_cancel'>avbryt</a>"
                       + "      </div>"
                       + "    </form>"
                       + "  </div></div>"
                       + "  <div class='column column2'><div class='inner'>"
                       + "    <ul class='tabs'>"
                       + "      <li><a href='#' id='toggle_navigation' class='current'>Välj sida från navigationen</a></li>"
                       + "    </ul>"
                       + "    <div id='navigation' class='minimal' style='display:none'><h3>Laddar sidor...</h3></div>"
                       + "  </div></div>"
                       + "</div>"
                       + "<script type='text/javascript' src='/javascripts/porthos/jquery/jquery.js'></script>"
                       + "<script type='text/javascript' src='/javascripts/porthos/wymeditor/jquery.wymeditor.js'></script>"
                       + "<script type='text/javascript' src='/javascripts/named_routes.js'></script>"
                       + "<script type='text/javascript' src='/javascripts/porthos/jquery.wymeditor.porthos-linking.js'></script>"
                       + "<script type='text/javascript' src='/javascripts/porthos/jquery.form.js'></script>"
                       + "</body>"
});

Porthos.Editor.Initialize = function(selector, options) {
  var selector = selector || '#editor';
  var options = Object.extend(Porthos.Editor.Options, options || {});
  var editors = Porthos.jQuery(selector);
  var filters = Porthos.jQuery('#resource_filter option').map(function() {
    return Porthos.jQuery(this).val();
  });
  var filter_select = Porthos.jQuery('#resource_filter');
  filter_select.data('old_value', filter_select.val());
  filter_select.change(function() {
    var self = Porthos.jQuery(this);
    self.blur();
    var value = self.val();
    var filter_string = ''
    filters.each(function() {
      filter_string += ' '+this;
    });
    editors.removeClass(filter_string)
    .addClass(value);
        
    // Teardowns
    switch(self.data('old_value')) {
      case 'wymeditor':
        for(i=0; i < WYMeditor.INSTANCES.length; i++) {
          WYMeditor.INSTANCES[i].destroy();
        }
        break;
      case 'html':
        Porthos.jQuery(selector).val(Porthos.Editor.code_mirror.getCode()).show();
        jQuery('.CodeMirror-wrapping').remove();
        delete Porthos.Editor.code_mirror;
        break;
    }

    switch(value) {
      case 'wymeditor':
        Porthos.jQuery(selector).wymeditor(options);
        break;
      case 'html':
        Porthos.Editor.code_mirror = CodeMirror.fromTextArea(Porthos.jQuery(selector).get(0), {
          height: "350px",
          parserfile: "parsexml.js",
          stylesheet: "/stylesheets/porthos/codemirror.css",
          path: "/javascripts/porthos/codemirror/",
          continuousScanning: 500,
          lineNumbers: true
        });
        break;
      default:
        Porthos.jQuery(selector).blur();
    }
    self.data('old_value', value);
  });
  editors.filter('.wymeditor').wymeditor(options);
  editors.filter('.html').each(function() {
    Porthos.Editor.code_mirror = CodeMirror.fromTextArea(this, {
      height: "350px",
      parserfile: "parsexml.js",
      stylesheet: "/stylesheets/porthos/codemirror.css",
      path: "/javascripts/porthos/codemirror/",
      continuousScanning: 500,
      lineNumbers: true
    });
  });
};