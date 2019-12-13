# coding: utf-8
require "pathname"
require "set"

require "redcarpet"
require "rouge"
require "rouge/plugins/redcarpet"

module SassHelpers
  def page_title
    title = "Sass: "
    if current_page.data.title
      title << current_page.data.title
    else
      title << "Syntactically Awesome Style Sheets"
    end
    title
  end

  def copyright_years(start_year)
    end_year = Date.today.year
    if start_year == end_year
      start_year.to_s
    else
      start_year.to_s + '&ndash;' + end_year.to_s
    end
  end

  def pages_for_group(group_name)
    group = data.nav.find do |g|
      g.name == group_name
    end

    pages = []

    return pages unless group

    if group.directory
      pages << sitemap.resources.select { |r|
        r.path.match(%r{^#{group.directory}}) && !r.data.hidden
      }.map do |r|
        ::Middleman::Util.recursively_enhance({
          :title => r.data.title,
          :path  => r.url
        })
      end.sort_by { |p| p.title }
    end

    pages << group.pages if group.pages

    pages.flatten
  end

  def without_html(page)
    url_for(page).sub(/\.html$/, '')
  end

  def documentation_toc
    _toc_level(nil, data.documentation.toc)
  end

  def _toc_level(parent_href, links)
    if parent_href
      overview = content_tag(:li,
        content_tag(:a, "Overview", href: parent_href,
          class: ("selected" if current_page.url == parent_href + ".html")),
        class: "overview")
    end

    content_tag(:ul, [
      overview,
      *links.map do |link|
        children = link[:children]
        text = link.keys.reject {|k| k == :children}.first
        href = link[text]

        content_tag(:li, [
          content_tag(:a, text, href: href,
            class: [
              ("section" if children),
              ("open selected" if current_page.url.start_with?(href))
            ].compact.join(" ")),
          (_toc_level(href, children) if children)
        ].compact)
      end
    ].compact)
  end

  # Renders a code example.
  #
  # This takes a block of SCSS and/or indented syntax code, and emits HTML that
  # (combined with JS) will allow users to choose which to display.
  #
  # The SCSS should be separated from the Sass with `===`. For example, in Haml:
  #
  #     - example do
  #       :plain
  #         .foo {
  #           color: blue;
  #         }
  #         ===
  #         .foo
  #           color: blue
  #
  # Different sections can be separated within one syntax (for example, to
  # indicate different files) with `---`. For example, in Haml:
  #
  #     - example do
  #       :plain
  #         // _reset.scss
  #         * {margin: 0}
  #         ---
  #         // base.scss
  #         @import 'reset';
  #         ===
  #         // _reset.sass
  #         *
  #           margin: 0;
  #         ---
  #         // base.sass
  #         @import reset
  #
  # Padding is added to the bottom of each section to make it the same length as
  # the section in the other language.
  #
  # A third section may optionally be provided to represent compiled CSS. If
  # it's not passed and `autogen_css` is `true`, it's generated from the SCSS
  # source. If the autogenerated CSS is empty, it's omitted entirely.
  #
  # If `syntax` is either `:sass` or `:scss`, the first section will be
  # interpreted as that syntax and the second will be interpreted (or
  # auto-generated) as the CSS output.
  def example(autogen_css: true, syntax: nil, &block)
    contents = _capture(&block)

    if syntax == :scss
      scss, css = contents.split("\n===\n")
    elsif syntax == :sass
      sass, css = contents.split("\n===\n")
    else
      scss, sass, css = contents.split("\n===\n")
      throw ArgumentError.new("Couldn't find === in:\n#{contents}") if sass.nil?
    end

    scss_sections = scss ? scss.split("\n---\n").map(&:strip) : []
    sass_sections = sass ? sass.split("\n---\n").map(&:strip) : []

    if css.nil? && autogen_css
      sections = scss ? scss_sections : sass_sections
      if sections.length != 1
        throw ArgumentError.new(
                "Can't auto-generate CSS from more than one SCSS file.")
      end

      css = Sass::Engine.new(
        sections.first,
        syntax: syntax || :scss,
        style: :expanded
      ).render
      css = nil if css.empty?
    end
    css_sections = css ? css.split("\n---\n").map(&:strip) : []

    # Calculate the lines of padding to add to the bottom of each section so
    # that it lines up with the same section in the other syntax.
    scss_paddings = []
    sass_paddings = []
    css_paddings = []
    max_num_sections =
      [scss_sections, sass_sections, css_sections].map(&:length).max
    max_num_sections.times do |i|
      scss_section = scss_sections[i]
      sass_section = sass_sections[i]
      css_section = css_sections[i]
      scss_lines = (scss_section || "").lines.count
      sass_lines = (sass_section || "").lines.count
      css_lines = (css_section || "").lines.count

      # Whether the current section is the last section for the given syntax.
      last_scss_section = i == scss_sections.length - 1
      last_sass_section = i == sass_sections.length - 1
      last_css_section = i == css_sections.length - 1

      # The maximum lines for any syntax in this section, ignoring syntaxes for
      # which this is the last section.
      max_lines = [
        last_scss_section ? 0 : scss_lines,
        last_sass_section ? 0 : sass_lines,
        last_css_section ? 0 : css_lines
      ].max

      scss_paddings <<
        if last_scss_section
          # Make sure the last section has as much padding as all the rest of
          # the other syntaxes' sections.
          _total_padding(sass_sections[i..-1], css_sections[i..-1]) -
            scss_lines - 2
        elsif max_lines > scss_lines
          max_lines - scss_lines
        end

      sass_paddings <<
        if last_sass_section
          _total_padding(scss_sections[i..-1], css_sections[i..-1]) -
            sass_lines - 2
        elsif max_lines > sass_lines
          max_lines - sass_lines
        end

      css_paddings <<
        if last_css_section
          _total_padding(scss_sections[i..-1], sass_sections[i..-1]) -
            css_lines - 2
        elsif max_lines > css_lines
          max_lines - css_lines
        end
    end

    @unique_id ||= 0
    @unique_id += 1
    id = @unique_id
    ul_contents = []
    ul_contents << _syntax_tab("SCSS", "scss", id, enabled: scss) if scss
    ul_contents << _syntax_tab("Sass", "sass", id, enabled: !scss) if sass
    ul_contents << _syntax_tab("CSS", "css", id) if css

    contents = [
      content_tag(:ul, ul_contents,
        class: "ui-tabs-nav ui-helper-reset ui-helper-clearfix")
    ]
    if scss
      contents <<
        _syntax_div("SCSS Syntax", "scss", scss_sections, scss_paddings, id, enabled: scss)
    end
    if sass
      contents <<
        _syntax_div("Sass Syntax", "sass", sass_sections, sass_paddings, id, enabled: !scss)
    end
    if css
      contents <<
        _syntax_div("CSS Output", "css", css_sections, css_paddings, id)
    end

    max_source_width = (scss_sections + sass_sections).map {|s| s.split("\n")}.flatten.map(&:size).max
    max_css_width = css_sections.map {|s| s.split("\n")}.flatten.map(&:size).max

    can_split = max_css_width && (max_source_width + max_css_width) < 110
    if can_split
      if max_source_width < 55 && max_css_width < 55
        split_location = 0.5
      else
        # Put the split exactly in between the two longest lines.
        split_location = 0.5 + (max_source_width - max_css_width) / 110.0 / 2
      end
    end

    text = content_tag(:div, contents,
      class: "code-example ui-tabs #{'can-split' if can_split}",
      "style": ("--split-location: #{split_location * 100}%" if split_location))

    # Newlines between tags cause Markdown to parse these blocks incorrectly.
    text = text.gsub(%r{\n+<(/?[a-z0-9]+)}, '<\1')
    if block_is_haml?(block)
      haml_concat text
    else
      # Padrino's concat helper doesn't play nice with nested captures.
      @_out_buf << text
    end
  end

  # Returns the number of lines of padding that's needed to match the height of
  # the `<pre>`s generated for `sections1` and `sections2`.
  def _total_padding(sections1, sections2)
    sections1 ||= []
    sections2 ||= []
    [sections1, sections1].map(&:length).max.times.sum do |i|
      # Add 2 lines to each additional section: 1 for the extra padding, and 1
      # for the extra margin.
      [
        (sections1[i] || "").lines.count,
        (sections2[i] || "").lines.count
      ].max + 2
    end
  end

  # Returns the text of an example tab for a single syntax.
  def _syntax_tab(name, syntax, id, enabled: false)
    content_tag(:li, [
      content_tag(:a, name, href: "#example-#{id}-#{syntax}", class: "ui-tabs-anchor")
    ], class: [
      "ui-tabs-tab",
      ('css-tab' if syntax == 'css'),
      ('ui-tabs-active' if enabled)
    ].compact.join(' '))
  end

  # Returns the text of an example div for a single syntax.
  def _syntax_div(name, syntax, sections, paddings, id, enabled: false)
    inactive = syntax == 'scss' ? '' : 'ui-tabs-panel-inactive'
    content_tag(:div, [
      content_tag(:h3, name, class: 'visuallyhidden'),
      *sections.zip(paddings).map do |section, padding|
        padding = 0 if padding.nil? || padding.negative?
        _render_markdown("```#{syntax}\n#{section}#{"\n" * padding}\n```")
      end
    ], id: "example-#{id}-#{syntax}", class: [
      "ui-tabs-panel",
      syntax,
      ('ui-tabs-panel-inactive' unless enabled)
    ].compact.join(' '))
  end

  # Returns the version for the given implementation (`:dart`, `:ruby`, or
  # `:libsass`), or `nil` if it hasn't been made available yet.
  def impl_version(impl)
    data.version && data.version[impl]
  end

  # Returns the URL tag for the latest release of the given implementation.
  def release_url(impl)
    if impl == :ruby
      return "https://github.com/sass/ruby-sass/blob/stable/doc-src/SASS_CHANGELOG.md"
    end

    version = impl_version(impl)
    repo =
      case impl
      when :dart; "dart-sass"
      when :migrator; "migrator"
      when :libsass; "libsass"
      end

    if version
      "https://github.com/sass/#{repo}/releases/tag/#{version}"
    else
      "https://github.com/sass/#{repo}/releases"
    end
  end

  # Returns HTML for a warning.
  #
  # The contents should be supplied as a block.
  def heads_up
    _concat(content_tag :div, [
      content_tag(:h3, '⚠️ Heads up!'),
      _render_markdown(_capture {yield})
    ], class: 'sl-c-callout sl-c-callout--warning')
  end

  # Returns HTML for a fun fact that's not directly relevant to the main
  # documentation.
  #
  # The contents should be supplied as a block.
  def fun_fact
    _concat(content_tag :div, [
      content_tag(:h3, '💡 Fun fact:'),
      _render_markdown(_capture {yield})
    ], class: 'sl-c-callout sl-c-callout--fun-fact')
  end

  def table_of_contents(resource)
    content = File.read(resource.source_file)
    toc_renderer = Redcarpet::Render::HTML_TOC.new
    markdown = Redcarpet::Markdown.new(toc_renderer)
    markdown.render(content)
  end

  def markdown_wrap(content)
    Tilt['markdown'].new { content }.render
  end

  # Renders a status dashboard for each implementation's support for a feature.
  #
  # Each implementation's value can be:
  #
  # * `true`, indicating that that implementation fully supports the feature;
  # * `false`, indicating that it does not yet support the feature at all;
  # * `:partial`, indicating that it has limited or incorrect support for the
  #   feature;
  # * or a string, indicating the version it started supporting the feature.
  #
  # When possible, prefer using the start version rather than `true`.
  #
  # If `feature` is passed, it should be a terse (one- to three-word)
  # description of the particular feature whose compatibility is described. This
  # should be used whenever the status isn't referring to the entire feature
  # being described by the surrounding prose.
  #
  # This takes an optional Markdown block that should provide more information
  # about the implementation differences or the old behavior.
  def impl_status(dart: nil, libsass: nil, ruby: nil, node: nil, feature: nil)
    compatibility = feature ? "Compatibility (#{feature}):" : "Compatibility:"

    contents = [content_tag(:div, compatibility, class: "compatibility")]
    contents << _impl_status_row('Dart Sass', dart) unless dart.nil?
    contents << _impl_status_row('LibSass', libsass) unless libsass.nil?
    contents << _impl_status_row('Node Sass', node) unless node.nil?
    contents << _impl_status_row('Ruby Sass', ruby) unless ruby.nil?

    if block_given?
      contents << content_tag(:div, content_tag(:a, '▶'))
    end

    _concat(content_tag(:dl, contents, class: 'impl-status sl-c-description-list sl-c-description-list--horizontal'))

    if block_given?
      # Get rid of extra whitespace to avoid more bogus <p> tags.
      _concat(content_tag :div, _render_markdown(_capture {yield}).strip, class: 'sl-c-callout sl-c-callout--impl-status')
    end
  end

  # Renders a single row for `impl_status`.
  def _impl_status_row(name, status)
    status_text =
      if status == true
        "✓"
      elsif status == false
        "✗"
      elsif status == :partial
        "partial"
      else
        "since #{status}"
      end

    content_tag :div, [
      content_tag(:dt, name),
      content_tag(:dd, status_text),
    ]
  end

  # Renders API docs for a Sass function (or mixin).
  #
  # The function's name is parsed from the signature. The API description is
  # passed as a Markdown block. If `returns` is passed, it's included as the
  # function's return type.
  #
  # Multiple signatures may be passed, in which case they're all included in
  # sequence.
  def function(*signatures, returns: nil)
    names = Set.new
    highlighted_signatures = signatures.map do |signature|
      name, rest = signature.split("(", 2)
      name_without_namespace = name.split(".").last
      html = Nokogiri::HTML(_render_markdown(<<MARKDOWN))
```scss
@function #{signature}
{}
```
MARKDOWN
      signature_elements = html.css("pre code").children.
        drop_while {|el| el.text != "@function"}.
        take_while {|el| el.text != "{}"}[1...-1]

      # Add a class to make it easier to index function documentation.
      unless names.include?(name_without_namespace)
        names << name_without_namespace
        name_element = signature_elements.find {|el| el.text == name_without_namespace}
        name_element.add_class ".docSearch-function"
        name_element['name'] = name
      end

      signature_elements.map(&:to_html).join.strip.gsub("\n", "&#x0000A")
    end

    merged_signatures = highlighted_signatures.join("&#x0000A")
    if returns
      merged_signatures << " " <<
        content_tag(:span, "//=> #{return_type_link(returns)}", class: 'c1')
    end

    html = content_tag :div, [
      content_tag(:pre, [
        # Make sure there's no whitespace between these two, since they're in a
        # <pre>.
        content_tag(:a, '', class: 'anchor', href: "##{names.first}") +
          content_tag(:code, merged_signatures)
      ], class: 'signature highlight scss'),

      _render_markdown(_capture {yield})
    ], class: 'sl-c-callout sl-c-callout--function', id: names.first

    _concat(names.uniq[1..-1].inject(html) {|h, n| content_tag(:div, h, id: n)})
  end

  def return_type_link(return_type)
    return_type.split("|").map do |type|
      type = type.strip
      case type.strip
      when 'number'; link_to type, '/documentation/values/numbers'
      when 'string'; link_to type, '/documentation/values/strings'
      when 'quoted string'; link_to type, '/documentation/values/strings#quoted'
      when 'unquoted string'; link_to type, '/documentation/values/strings#unquoted'
      when 'color'; link_to type, '/documentation/values/colors'
      when 'list'; link_to type, '/documentation/values/lists'
      when 'map'; link_to type, '/documentation/values/maps'
      when 'boolean'; link_to type, '/documentation/values/booleans'
      when 'null'; link_to '<code>null</code>', '/documentation/values/null'
      when 'function'; link_to type, '/documentation/values/functions'
      when 'selector'; link_to type, '/documentation/modules/selector#selector-values'
      else raise "Unknown type #{type}"
      end
    end.join(" | ")
  end

  # Removes leading spaces from every non-empty line in `text` while preserving
  # relative indentation.
  def remove_leading_indentation(text)
    text.gsub(/^#{text.scan(/^ *(?=\S)(?!<)/).min}/, "")
  end

  # A helper method that renders a chunk of Markdown text.
  def _render_markdown(content)
    @redcarpet ||= Redcarpet::Markdown.new(
      Class.new(Redcarpet::Render::HTML) { include Rouge::Plugins::Redcarpet },
      markdown
    )
    find_and_preserve(@redcarpet.render(content))
  end

  # Captures the contents of `block` from ERB or Haml.
  #
  # Strips all leading indentation from the block.
  def _capture(&block)
    remove_leading_indentation(
      (block_is_haml?(block) ? capture_haml(&block) : capture(&block)) || "")
  end

  # Concatenates `text` to the document.
  #
  # Converts all newlines to spaces in order to avoid weirdness when rendered
  # HTML is nested within Markdown. Adds newlines before and after the content
  # to ensure that it doesn't cause adjacent markdown not to be parsed.
  def _concat(text)
    concat("\n\n" + text.gsub("\n", " ") + "\n\n")
  end
end
