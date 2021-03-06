if (typeof LowPro != "undefined") {
  // Add iframe to LowPro element builders
  (function() {
	  window['$iframe'] = DOM.Builder.tagFunc('iframe');
  })();
}

Math.roundWithPrecision = function(floatnum, precision) {
  return Math.round ( floatnum * Math.pow ( 10, precision ) ) / Math.pow ( 10, precision );
};

Math.formatBytes = function(bytes) {
  var size;
  var unit;

  // Terabytes (TB).
  if ( bytes >= 1099511627776 ) {
    size = bytes / 1099511627776;
    unit = ' TB';
  // Gigabytes (GB).
  } else if ( bytes >= 1073741824 ) {
    size = bytes / 1073741824;
    unit = ' GB';
  // Megabytes (MB).
  } else if ( bytes >= 1048576 ) {
    size = bytes / 1048576;
    unit = ' MB';
  // Kilobytes (KB).
  } else if ( bytes >= 1024 ) {
    size = bytes / 1024;
    unit = ' KB';
  // The file is less than one KB
  } else {
    size = bytes;
    unit = ' bytes';
  }
   
  // Single-digit numbers have greater precision
  var precision = 1;
  if (size < 10) {
    precision = 2;
  }
  size = Math.roundWithPrecision(size, precision);

  // Add the decimal if this is an integer
  if ((size % 1) == 0 && unit != ' bytes') {
    size = size + '.0';
  }

  return size + unit;
};

if (typeof Porthos == "undefined") {
    var Porthos = {};
}
Porthos.namespace = function() {
  var a=arguments, o=null, i, j, d;
  for (i=0; i<a .length; i=i+1) {
    d = a[i].split(".");
    o = window;
    for (j=0; j<d.length; j=j+1) {
      o[d[j]]=o[d[j]] || {};
      o=o[d[j]];
    }
  }
  return o;
};

Porthos.extract_id = new RegExp(/([A-z]|\_|\-)*/i);
Porthos.extractId = function(string) {
  return string.replace(Porthos.extract_id,'');
};


Object.extend(Porthos, {
  
  authenticityTokenParameter: function(){
    return this.authenticity().key + '=' + encodeURIComponent(this.authenticity().token);
  },
  
  authenticity: function() {
    if (!this._authenticity) {
      this._authenticity = $('authenticity-token');
    }
    return {
      key : this._authenticity.name,
      token : this._authenticity.content
    }
  }

});

Ajax.Base.prototype.initialize = Ajax.Base.prototype.initialize.wrap(function() {
  var args = $A(arguments), proceed = args.shift();
  var options = args[0];
  if (Object.isString(options.parameters)) {
    options.parameters += '&' + Porthos.authenticityTokenParameter();
  } else if (Object.isHash(options.parameters)) {
    options.parameters = this.options.parameters.toObject();
    options.parameters[Porthos.authenticity().key] = Porthos.authenticity().token;
  } else if (options.parameters != undefined) {
    options.parameters[Porthos.authenticity().key] = Porthos.authenticity().token;
  }
  proceed.apply(null, args);
});

/*
  parseUri 1.2.1
  (c) 2007 Steven Levithan <stevenlevithan.com>
  MIT License
*/

Porthos.parseUri = function(str) {
  var o = Porthos.parseUri.options,
  m   = o.parser[o.strictMode ? "strict" : "loose"].exec(str),
  uri = {},
  i   = 14;

  while (i--) {
    uri[o.key[i]] = m[i] || "";
  }

  uri[o.q.name] = {};
  uri[o.key[12]].replace(o.q.parser, function ($0, $1, $2) {
    if ($1) uri[o.q.name][$1] = $2;
  });

  return uri;
};

Porthos.parseUri.options = {
  strictMode: false,
  key: ["source","protocol","authority","userInfo","user","password","host","port","relative","path","directory","file","query","anchor"],
  q:   {
    name:   "queryKey",
    parser: /(?:^|&)([^&=]*)=?([^&]*)/g
  },
  parser: {
    strict: /^(?:([^:\/?#]+):)?(?:\/\/((?:(([^:@]*):?([^:@]*))?@)?([^:\/?#]*)(?::(\d*))?))?((((?:[^?#\/]*\/)*)([^?#]*))(?:\?([^#]*))?(?:#(.*))?)/,
    loose:  /^(?:(?![^:@]+:[^:@\/]*@)([^:\/?#.]+):)?(?:\/\/)?((?:(([^:@]*):?([^:@]*))?@)?([^:\/?#]*)(?::(\d*))?)(((\/(?:[^?#](?![^?#\/]*\.[^?#\/.]+(?:[?#]|$)))*\/?)?([^?#\/]*))(?:\?([^#]*))?(?:#(.*))?)/
  }
};

Porthos.IframeObserver = Class.create(Abstract.TimedObserver, {
  getValue: function() {
    return this.getElement().innerHTML.unescapeHTML();
  },
  getElement: function() {
    var iframe = this.element.contentWindow ? this.element.contentWindow.document : this.element.contentDocument;
    return (iframe.body || iframe.documentElement);
  },    
  resetElement: function() {
    this.clearCallback();
    this.getElement().innerHTML = '';
  },
  registerCallback: function() {
    this.interval = setInterval(this.onTimerEvent.bind(this), this.frequency * 1000);
  },
  clearCallback: function() {
    clearInterval(this.interval);
  }
});

Porthos.namespace('Porthos.Helpers');
Porthos.Helpers.buttonTo = function(options) {
  var options = Object.extend({
    'method': 'get',
    'action': '',
    'class' : 'button_to',
    'name'  : 'Send'
  }, options);

  var button_options = {
    'type' : (!options['src']) ? 'submit' : 'image',
    'value': options['name'],
  };

  if (button_options['type'] == 'image') {
    button_options['src'] = options['src'];
  }


  var container = $div();
  if ($A(['put', 'delete']).include(options['method'])) {
    container.appendChild($input({
      'type' : 'hidden',
      'name' : '_method',
      'value': options['method']
    }));
  }

  button = $input(button_options);
  container.appendChild(button);
  if (options['confirm']) {
    button.onclick = function() {
      return confirm(options['confirm']);
    };
  }

  form_method = (options['method'] == 'get') ? 'get' : 'post';
  form = $form({
    'action': options['action'],
    'method': form_method,
    'class' : options['class']
  }, container);

  return form;
};

Porthos.Helpers.graphicLabel = function(element) {
  var labels = $A(element.getElementsByTagName('label'));
  labels.invoke('observe', 'click', function(event) {
    labels.invoke('removeClassName', 'checked');
    $(this).addClassName('checked');
  });
};

Object.extend(String.prototype, {
  toUrl: function() {
    var source = this;
    source = source.strip().toLowerCase();
    var from = "åäöàáäâèéëêìíïîòóöôùúüûÑñÇç·/_,:;";
    var to   = "aaoaaaaeeeeiiiioooouuuunncc------";
    for (var i = 0, l = from.length; i < l; i++) {
      source = source.replace(new RegExp(from[i], 'g'), to[i]);
    }
    return source.replace(/[^a-zA-Z0-9 -]/g, '').replace(/\s+/g, '-');
  }
});

Porthos.Helpers.cloneAsUrl = function(source, target) {
  var source = $(source), target = $(target);
  if (!source || !target) { return; }
  target.store('clone_from_title', target.getValue().empty());
  source.observe('keyup', function(event) {
    if (target.retrieve('clone_from_title') == true) {
      target.value = $(this).getValue().toUrl();
    }
  });
  target.observe('change', function(event) {
    var value = $(this).getValue();
    if (!value.empty()) {
      if (value != source.getValue().toUrl()) {
        target.store('clone_from_title', false);
      }
    } else {
      target.store('clone_from_title', true);
    }
  });
};

Porthos.Sorting = Class.create({
  initialize: function(el, list, serialized_name) {
    if($(el) == null) { return; }
    
    this.sorting = false;
    this.serialized_name = serialized_name || 'items'
    this.sorting_link = $(el);
    this.list = $(list);
    this.setup();
  },
  
  setup: function() {
    this.sorting_link.observe('click', function(ev){
      this.old_list_state = this.list.cloneNode(true);
      if(this.sorting == false) {
        Sortable.create(this.list, { handle: 'draghandle' });
        this.save_button = $input({ 'type': 'submit', 'value': 'Spara sortering', 'class': 'button' });
        this.cancel_link = $a({ 'href': '' }, 'Avbryt');
        this.cancel_link.observe('click', function(ev){
          this.list.replace(this.old_list_state);
          this.list = this.old_list_state;
          this.old_list_state = null;
          this.tearDown();
          Event.stop(ev);
        }.bind(this));
        form = $form({ 'action': this.sorting_link.href }, this.save_button, ' eller ', this.cancel_link );          
        Element.insert(this.sorting_link.parentNode, { after: $div({ 'class': 'confirm', 'id': 'save_sorting_container' }, form) });
        form.observe('submit', function(sort_event) {
          this.save();
          sort_event.stop();
        }.bind(this));     
        this.list.addClassName('sorting');
        this.sorting = true;
      }
      ev.stop();
    }.bind(this));
  },
  
  save: function() {      
    new Ajax.Request(this.sorting_link.href, {
      method: 'put',
      parameters: Sortable.serialize(this.list, {name: this.serialized_name}), 
      onComplete: function(response) {
        this.tearDown();
      }.bind(this)
    });
  },
  
  tearDown: function() {
    Sortable.destroy(this.list);
    $('save_sorting_container').remove();
    this.list.removeClassName('sorting');
	  this.sorting = false;
  }
});

Porthos.TagAutoCompletion = Class.create({
  initialize: function (element){
    Element.insert(element, {
    'after': $div({
      'id': 'tags_list_'+element.id,
      'class' : 'tags autocomplete'
      })
    });
    new Ajax.Autocompleter(element, 'tags_list_'+element.id, Routing.search_admin_tags_path({ 'format' : 'js' }), { 
      'select'    : '.tag', 
      'tokens'    : ' ', 
      'paramName' : 'query', 
      'method'    : 'get',
      afterUpdateElement: function(targetInput, sourceLi){ targetInput.value += ' '; }
    });
  }
});

Porthos.SearchFieldAutoClear = function() {
  $$('input.search_query').each(function(input) {
    input.observe('focus', function(ev) {
      if (!input.orginal_value) {
        input.orginal_value = input.value;
      }
      if (input.value == input.orginal_value) {
        input.value = '';
      }
    });
    input.observe('blur', function(ev) {
      if (input.value == '') {
        input.value = input.orginal_value;
      }  
    });
  });
};
document.observe('dom:loaded', function() {
  Porthos.SearchFieldAutoClear();
  $$('#asset_usages.sortable').each(function(element) {
    Sortable.create(element, {
      handle: 'drag_handle',
      tag: 'div',
      onUpdate: function() {
        new Ajax.Request(Routing.sort_admin_asset_usages_path(), {
          method: 'put',
          parameters: Sortable.serialize(element)
        });
      }
    })
  });
});
