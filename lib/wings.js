
(function(wings) {
  var escapeXML, isArray, parsePattern, renderRawTemplate, replaceBraces, restoreBraces;
  wings.strict = false;
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
  isArray = Array.isArray || (function(o) {
    return Object.prototype.toString.call(o) === '[object Array]';
  });
  escapeXML = function(s) {
    return s.toString().replace(/&(?!\w+;)|["<>]/g, function(s) {
      switch (s) {
        case '&':
          return '&amp;';
        case '"':
          return '\"';
        case '<':
          return '&lt;';
        case '>':
          return '&gt;';
        default:
          return s;
      }
    });
  };
  parsePattern = /\s*\{([:!])\s*([^}]*?)\s*\}([\S\s]+?)\s*\{\/\s*\2\s*\}|\{(\#)[\S\s]+?\#\}|\{([@&]?)\s*([^}]*?)\s*\}/mg;
  return renderRawTemplate = function(template, data, links) {
    return template.replace(parsePattern, function(all, sectionOp, sectionName, sectionContent, commentOp, tagOp, tagName) {
      var content, i, link, name, op, part, parts, rest, v, value, _len, _ref;
      op = sectionOp || commentOp || tagOp;
      name = sectionName || tagName;
      content = sectionContent;
      switch (op) {
        case ':':
          value = data[name];
          if (!(value != null)) {
            if (wings.strict) {
              throw "Invalid section: " + (JSON.stringify(data)) + ": " + name;
            } else {
              return "";
            }
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
            if (wings.strict) {
              throw "Invalid inverted section: " + (JSON.stringify(data)) + ": " + name;
            } else {
              return "";
            }
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
            if (wings.strict) {
              throw "Invalid link: " + (JSON.stringify(links)) + ": " + name;
            } else {
              return "";
            }
          } else if (typeof link === 'function') {
            link = link.call(data);
          }
          return renderRawTemplate(replaceBraces(link), data, links);
        case '&':
        case '':
          value = data;
          rest = name;
          while (value && rest) {
            _ref = rest.match(/^([^.]*)\.?(.*)$/), all = _ref[0], part = _ref[1], rest = _ref[2];
            value = value[part];
          }
          if (!(value != null)) {
            if (wings.strict) {
              throw "Invalid value: " + (JSON.stringify(data)) + ": " + name;
            } else {
              return "";
            }
          } else if (typeof value === 'function') {
            value = value.call(data);
          }
          return (op === '&' ? value : escapeXML(value));
        default:
          throw "Invalid section op: " + op;
      }
    });
  };
})(typeof exports !== "undefined" && exports !== null ? exports : (this['wings'] = {}));
