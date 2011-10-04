!(function(wings) {
  var escapeXML, isArray, parse_re, renderRawTemplate, replaceBraces, restoreBraces, _ref;
  wings.renderTemplate = function(template, data, links) {
    template = replaceBraces(template);
    template = renderRawTemplate(template, data, links);
    template = restoreBraces(template);
    return template;
  };
  replaceBraces = function(template) {
    return template.replace(/\{\{/g, '\ufe5b').replace(/\}\}/g, '\ufe5d');
  };
  restoreBraces = function(template) {
    return template.replace(/\ufe5b/g, '{').replace(/\ufe5d/g, '}');
  };
  isArray = (_ref = Array.isArray) != null ? _ref : (function(o) {
    return Object.prototype.toString.call(o) === '[object Array]';
  });
  escapeXML = function(s) {
    return (s || '').toString().replace(/&(?!\w+;)|["<>]/g, function(s) {
      switch (s) {
        case '&':
          return '&amp';
        case '"':
          return '\"';
        case '<':
          return '&lt';
        case '>':
          return '&gt';
        default:
          return s;
      }
    });
  };
  parse_re = /\s*\{([!:])\s*([^}]*?)\s*\}([\S\s]+?)\s*\{\\/\s*\2\s*\}|\{([@&]?)\s*([^}]*?)\s*\}|\{(\#)\s*[\S\s]+?\s*\#\}/mg;
  return renderRawTemplate = function(template, data, links) {
    return template.replace(parse_re, function(match, section_op, section_name, section_content, tag_op, tag_name, comment_op) {
      var content, i, link, name, op, part, parts, v, value, _len, _ref2;
      op = section_op || tag_op || comment_op;
      name = section_name || tag_name;
      content = section_content;
      switch (op) {
        case ':':
          value = data[name];
          if (!(value != null)) {
            throw "Invalid section: " + data + ": " + name + ": " + value;
          } else if (isArray(value)) {
            parts = [];
            for (i = 0, _len = value.length; i < _len; i++) {
              v = value[i];
              v['#'] = i;
              parts.push(renderRawTemplate(content, v, links));
            }
            return parts.join('');
          } else if (typeof value === 'object') {
            return renderRawTemplate(content, value, links);
          } else if (typeof value === 'function') {
            return value.call(data, content);
          } else if (value) {
            return renderRawTemplate(content, data, links);
          } else {
            return "";
          }
          break;
        case '!':
          value = data[name];
          if (!(value != null)) {
            throw "Invalid inverted section: " + data + ": " + name + ": " + value;
          } else if (!value || (isArray(value) && value.length === 0)) {
            return renderRawTemplate(content, data, links);
          } else {
            return "";
          }
          break;
        case '#':
          return '';
        case '@':
          link = links ? links[name] : null;
          if (!(link != null)) {
            throw "Invalid link: " + links + ": " + name + ": " + link;
          } else if (typeof link === 'function') {
            link = link.call(data);
          }
          return renderRawTemplate(replaceBraces(link), data, links);
        case '&':
        case '':
          value = data;
          while (value && name) {
            _ref2 = name.match(/^([^.]*)\.?(.*)$/).slice(1), part = _ref2[0], name = _ref2[1];
            if (part in value) {
              value = value[part];
            } else {
              value = null;
            }
          }
          if (!(value != null)) {
            throw "Invalid value: " + data + ": " + name + ": " + value;
          } else if (typeof value === 'function') {
            value = value.call(data);
          }
          if (op === '&') {
            return value;
          } else {
            return escapeXML(value);
          }
      }
    });
  };
})(typeof exports !== "undefined" && exports !== null ? exports : (this['wings'] = {}));