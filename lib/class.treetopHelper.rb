
#
# this mixin provides a convenient interface
# for the syntaxtree
#

class Treetop::Runtime::SyntaxNode
    
    # this delivers a child node of the AST
    def child
        elements.select{|e| e.is_ast? } if ! elements.nil?
    end

    def ast_children
      elements.reject {|e| e.ast_module.nil? }
    end

    # returns an array of all descendants of the current node
    # in the AST in document order
    def descendant
        child.map{|e| [e, e.descendant] }.flatten.compact if not child.nil?
    end
    
    # returns this and all descendant in document order
    def thisdescendant
        [self, descendant].flatten
    end
    
    # returns all nodes to up to the AST root
    def ancestor
        if ! parent.nil?
            [parent, parent.ancestor].flatten
        end
    end
    
    # indicates if the current treetop node is important enough
    # to be in the intended AST
    def is_ast?
      true # nonterminal? # parent.nil? or extension_modules.include?(Xmine)
    end
    
    # indicates if a meaningful name for the node in the AST
    # is available
    def has_rule_name?
        not (extension_modules.nil? or extension_modules.empty?)
    end
    
    # returns a meaning name for the node in the AST
    def rule_name
        if has_rule_name? then
            extension_modules.first.name.split("::").last.gsub(/[0-9]/,"")
        elsif not getLabel.nil?
            getLabel
        else
            "###"
        end
    end
    
    # another quick info for a node
    def to_info
        rule_name + ": "+ text_value
    end

    def ast_module
      extension_modules.select {|m| (m.name[-1] =~ /[0-9]/).nil? }.first
    end

    def my_xml(tag = nil)
      mod = ast_module
      if not ast_module.nil?
        ctx = self
        typ = mod.name.split("::").last
        tag ||= typ

        r  = [ "<#{tag} type=\"#{typ}\">" ]
        r += mod.public_instance_methods.map do |roleName|
          children = ctx.send(roleName)

          descend = lambda do |my_child, role|
            role = role.to_s.gsub('?', '') unless role.nil?
            my_child.respond_to?(:my_xml) ? my_child.my_xml(role) : [ "<#{role}>#{my_child.to_s.encode(:xml => :text)}</#{role}>" ]
          end

          if children.is_a?(Array)
            [ "<#{roleName}>", children.map {|my_child| descend.call(my_child, nil) }, "</#{roleName}>" ]
          else
            descend.call(children, roleName)
          end
        end
        r << "</#{tag}>"
        r
      else
        text_value.to_s.encode(:xml => :text)
      end
    end

    def to_xml
      pp = lambda {|l, i, pp| l.map {|e| e.is_a?(Array) ? pp.call(e, i+1, pp) : "#{i.times.map{"  "}.join}#{e}" }.join("\n") }
      pp.call(my_xml, 0, pp)
    end

    # clean the tree by removing garbage nodes
    # which are not part of the intended AST
    def clean_tree(root_node)
        return if(root_node.elements.nil?)
        root_node.elements.delete_if{|node| not node.is_ast? }
        root_node.elements.each{|e| e.clean_tree(e)}
    end
end


class Treetop::Runtime::SyntaxNode
    def as_xml
        [(["<", getLabel, ">" ].join  if getLabel),
        (if elements
            elements.map { |e| e.as_xml }.join
            else
            text_value
        end),
        (["</", getLabel, ">" ].join  if getLabel)
        ].join
    end
    
    def wrap(tag,body)
        "<#{tag}>#{body}</#{tag}>"
    end
    
    def getLabel
        nil
    end
    
    
end


