

$LOAD_PATH.unshift(File.expand_path(File.dirname(File.dirname(__FILE__))))
require "rasterizer"


def split_into(array, n) 
	array.each_with_index.group_by do |element, index| 
		index % n
	end.values.map do |elements| 
		elements.map {|element,i| element}
	end
end

def build_examples_array(results, runs_path, results_path_info, num_chunks) 
	examples = []
	results['collections'].each do |template|
		rel_path = template['rel_output_path'] + "/" + template['collection_name']
		abs_path = runs_path + "/" + results_path_info.dirname.to_s + "/" + rel_path
		template['examples'].each do |example|

			examples << {
				rel_path: rel_path,
				abs_path: abs_path,
				filename: example.fetch('full_name')
			}
		end
	end
	examples.shuffle!
	example_chunks = split_into(examples, num_chunks)
end

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: example.rb [options]"

  opts.on("-r", "--results [file]", "Results json file") do |results|
  	options[:results] = results
  end

  opts.on("-o", "--runs-path [path]", "the path to the runs dir") do |path|
  	  	options[:runs_path] = path
	end

end.parse!

runs_path = options[:runs_path]
results_file = options[:results]
results_path_info = Pathname.new results_file
results =  JSON.parse(File.open(results_file).read)


example_chunks = build_examples_array(results, runs_path, results_path_info, 3)

num_examples = 0
example_chunks.each_with_index do |examples, index|
	fork { 
		examples.each do |example|
			t = Time.now
			command = "-d -F -D #{example[:abs_path]} -o #{example[:filename]}  #{example[:abs_path]}/#{example[:filename]}.html"
			`webkit2png #{command}`
			time = ((Time.now - t)*1000).round
			num_examples += 1
			puts "example #{num_examples} worker=#{index} time=#{time} example=#{example[:filename]}"
		end
	}
end

p Process.waitall
puts "done"




