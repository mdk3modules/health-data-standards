module HealthDataStandards
  module Export
    module ViewHelper
      def code_display(entry, options={})
        options['tag_name'] ||= 'code'
        options['attribute'] ||= :codes
        code_string = nil
        preferred_code = entry.preferred_code(options['preferred_code_sets'], options['attribute'])
        if preferred_code
          code_system_oid = HealthDataStandards::Util::CodeSystemHelper.oid_for_code_system(preferred_code['code_set'])
          code_string = "<#{options['tag_name']} code=\"#{preferred_code['code']}\" codeSystem=\"#{code_system_oid}\" #{options['extra_content']}>"
        else
          code_string = "<#{options['tag_name']} nullFlavor=\"UNK\" #{options['extra_content']}>"
        end
        
        code_string += "<originalText>#{ERB::Util.html_escape entry.description}</originalText>" if entry.respond_to?(:description)
        
        if entry.respond_to?(:translation_codes)
          entry.translation_codes(options['preferred_code_sets']).each do |translation|
            code_string += "<translation code=\"#{translation['code']}\" codeSystem=\"#{HealthDataStandards::Util::CodeSystemHelper.oid_for_code_system(translation['code_set'])}\"/>\n"
          end
        end
        
        code_string += "</#{options['tag_name']}>"
        code_string
      end
      
      def gc32_effective_time(entry)
        if entry.time
          "<effectiveTime value=\"#{Time.at(entry.time).to_formatted_s(:number)}\" />"
        elsif entry.start_time || entry.end_time
          time = "<effectiveTime>"
          time += "<start value=\"#{Time.at(entry.start_time).to_formatted_s(:number)}\" />"  if entry.start_time
          time += "<end value=\"#{Time.at(entry.end_time).to_formatted_s(:number)}\" />" if entry.end_time
          time += "</effectiveTime>"
        else
          "<effectiveTime />"
        end
      end
      
      def status_code_for(entry)
        case entry.status.to_s.downcase
        when 'active'
          '55561003'
        when 'inactive'
          '73425007'
        when 'resolved'
          '413322009'
        end
      end

           
      def value_or_null_flavor(time)
        if time 
          return "value='#{Time.at(time).utc.to_formatted_s(:number)}'"
        else 
         return "nullFlavor='UNK'"
       end
      end

      
      def quantity_display(value, tag_name="value")
        return unless value
        if value.respond_to?(:scalar)
          "<#{tag_name} value=\"#{value.scalar}\" units=\"#{value.units}\" />"
        else
          "<#{tag_name} value=\"#{value['value']}\" units=\"#{value['unit']}\" />"
        end
      end

      def time_if_not_nil(*args)
        args.compact.map {|t| Time.at(t).utc}.first
      end
      
      def is_num?(str)
        Float(str || "")
      rescue ArgumentError
        false
      else
        true
      end
      
      def is_bool?(str)
        return ["true","false"].include? (str || "").downcase
      end
      
      def decode_hqmf_section(section, oid)
        if oid
          HealthDataStandards::Util::HQMFTemplateHelper.definition_for_template_id(oid)['definition'].pluralize.to_sym
        else
          section
        end
      end
      def decode_hqmf_status(status, oid)
        if oid
          HealthDataStandards::Util::HQMFTemplateHelper.definition_for_template_id(oid)['status']
        else
          status
        end
      end
      
      def convert_field_to_hash(field, codes)
        binding.pry if field == 'negation'
        if (codes.is_a? Hash)
          clean_hash = {}
          
          if codes['codeSystem']
            clean_hash[codes['codeSystem']] = codes['code']
          elsif codes['_id']
            codes.keys.reject {|key| ['_id'].include? key}.each do |hashkey|
              value = codes[hashkey]
              if value.nil?
                clean_hash[hashkey.titleize] = 'none'
              elsif value.is_a? Hash
                clean_hash[hashkey.titleize] = convert_field_to_hash(hashkey, value)
              elsif value.is_a? Array
                clean_hash[hashkey.titleize] = value.join(', ')
              else
                clean_hash[hashkey.titleize] = convert_field_to_hash(hashkey, value)
              end
            end
          elsif codes['scalar']
            return "#{codes['scalar']} #{codes['units']}"
          else
            return codes.map {|hashcode_set, hashcodes| "#{hashcode_set}: #{(hashcodes.respond_to? :join) ? hashcodes.join(', ') : hashcodes.to_s}"}.join(' ')
          end
            
          clean_hash
        else
          if field.match(/Time$/) || field.match(/\_time$/)
            Entry.time_to_s(codes)
          else
            codes.to_s
          end
        end
      end
      
      
    end
  end
end