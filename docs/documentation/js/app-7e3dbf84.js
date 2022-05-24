function createSourceLinks(){$(".method_details_list .source_code").before("<span class='showSource'>[<a href='#' class='toggleSource'>View source</a>]</span>"),$(".toggleSource").toggle(function(){$(this).parent().nextAll(".source_code").slideDown(100),$(this).text("Hide source")},function(){$(this).parent().nextAll(".source_code").slideUp(100),$(this).text("View source")})}function createDefineLinks(){var e=0;$(".defines").after(" <a href='#' class='toggleDefines'>more...</a>"),$(".toggleDefines").toggle(function(){e=$(this).parent().prev().height(),$(this).prev().show(),$(this).parent().prev().height($(this).parent().height()),$(this).text("(less)")},function(){$(this).prev().hide(),$(this).parent().prev().height(e),$(this).text("more...")})}function createFullTreeLinks(){var e=0;$(".inheritanceTree").toggle(function(){e=$(this).parent().prev().height(),$(this).parent().toggleClass("showAll"),$(this).text("(hide)"),$(this).parent().prev().height($(this).parent().height())},function(){$(this).parent().toggleClass("showAll"),$(this).parent().prev().height(e),$(this).text("show all")})}function fixBoxInfoHeights(){$("dl.box dd.r1, dl.box dd.r2").each(function(){$(this).prev().height($(this).height())})}function searchFrameLinks(){$(".full_list_link").click(function(){return toggleSearchFrame(this,$(this).attr("href")),!1})}function toggleSearchFrame(e,t){var i=$("#search_frame");$("#search a").removeClass("active").addClass("inactive"),i.attr("src")==t&&"none"!=i.css("display")?(i.slideUp(100),$("#search a").removeClass("active inactive")):($(e).addClass("active").removeClass("inactive"),i.attr("src",t).slideDown(100))}function linkSummaries(){$(".summary_signature").click(function(){document.location=$(this).find("a").attr("href")})}function framesInit(){if(hasFrames){document.body.className="frames",$("#menu .noframes a").attr("href",document.location);try{window.top.document.title=$("html head title").text()}catch(e){}}else $("#menu .noframes a").text("frames").attr("href",framesUrl)}function keyboardShortcuts(){window.top.frames.main||$(document).keypress(function(e){if(!(e.altKey||e.ctrlKey||e.metaKey||e.shiftKey)&&("undefined"==typeof e.target||"INPUT"!=e.target.nodeName&&"TEXTAREA"!=e.target.nodeName))switch(e.charCode){case 67:case 99:$("#class_list_link").click();break;case 77:case 109:$("#method_list_link").click();break;case 70:case 102:$("#file_list_link").click()}})}function summaryToggle(){$(".summary_toggle").click(function(){return localStorage&&(localStorage.summaryCollapsed=$(this).text()),$(".summary_toggle").each(function(){$(this).text("collapse"==$(this).text()?"expand":"collapse");var e=$(this).parent().parent().nextAll("ul.summary").first();if(e.hasClass("compact"))e.toggle(),e.nextAll("ul.summary").first().toggle();else if(e.hasClass("summary")){var t=$('<ul class="summary compact" />');t.html(e.html()),t.find(".summary_desc, .note").remove(),t.find("a").each(function(){$(this).html($(this).find("strong").html()),$(this).parent().html($(this)[0].outerHTML)}),e.before(t),e.toggle()}}),!1}),localStorage&&("collapse"==localStorage.summaryCollapsed?$(".summary_toggle").first().click():localStorage.summaryCollapsed="expand")}function fixOutsideWorldLinks(){$("a").each(function(){window.location.host!=this.host&&(this.target="_parent")})}function generateTOC(){if(0!==$("#filecontents").length){var e,t=$('<ol class="top"></ol>'),i=!1,n=t,s=0,o=["h2","h3","h4","h5","h6"];for($("#filecontents h1").length>1&&o.unshift("h1"),e=0;e<o.length;e++)o[e]="#filecontents "+o[e];var r=parseInt(o[0][1],10);$(o.join(", ")).each(function(){if(0==$(this).parents(".method_details .docstring").length&&"filecontents"!=this.id){i=!0;var t=parseInt(this.tagName[1],10);if(0===this.id.length){var o=$(this).attr("toc-id");if("undefined"!=typeof o)this.id=o;else{var o=$(this).text().replace(/[^a-z0-9-]/gi,"_");$("#"+o).length>0&&(o+=s,s++),this.id=o}}if(t>r)for(e=0;t-r>e;e++){var a=$("<ol/>");n.append(a),n=a}if(r>t)for(e=0;r-t>e;e++)n=n.parent();var l=$(this).attr("toc-title");"undefined"==typeof l&&(l=$(this).text()),n.append('<li><a href="#'+this.id+'">'+l+"</a></li>"),r=t}}),i&&(html='<div id="toc"><p class="title"><a class="hide_toc" href="#"><strong>Table of Contents</strong></a> <small>(<a href="#" class="float_toc">left</a>)</small></p></div>',$("#content").prepend(html),$("#toc").append(t),$("#toc .hide_toc").toggle(function(){$("#toc .top").slideUp("fast"),$("#toc").toggleClass("hidden"),$("#toc .title small").toggle()},function(){$("#toc .top").slideDown("fast"),$("#toc").toggleClass("hidden"),$("#toc .title small").toggle()}),$("#toc .float_toc").toggle(function(){$(this).text("float"),$("#toc").toggleClass("nofloat")},function(){$(this).text("left"),$("#toc").toggleClass("nofloat")}))}}$(framesInit),$(createSourceLinks),$(createDefineLinks),$(createFullTreeLinks),$(fixBoxInfoHeights),$(searchFrameLinks),$(linkSummaries),$(keyboardShortcuts),$(summaryToggle),$(fixOutsideWorldLinks),$(generateTOC);