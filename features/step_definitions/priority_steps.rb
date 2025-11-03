Given('I have a project with attention gem installed') do
  expect(@test_root).to be_a(String)
  expect(File.directory?(@test_root)).to be true
end

Given('a critical production outage in the events service') do
  @service_path = File.join(@test_root, 'services', 'events')
  FileUtils.mkdir_p(@service_path)
end

When('I create an Attributes.ini file with:') do |content|
  file_path = File.join(@service_path || @test_root, 'Attributes.ini')
  File.write(file_path, content)
end

When('I create a Priorities.ini file with:') do |content|
  file_path = File.join(@service_path || @test_root, 'Priorities.ini')
  File.write(file_path, content)
end

When('I generate a priority report') do
  reporter = Attention::Reporter.new(@test_root)
  @report_output = reporter.priority_list
  @detailed_report = reporter.detailed_report
end

Then('the report should show {string} as the highest urgency item') do |attribute_name|
  expect(@detailed_report[:urgency_ranking].first[:attribute]).to eq(attribute_name)
end

Given('I have a root Attributes.ini with:') do |content|
  File.write(File.join(@test_root, 'Attributes.ini'), content)
end

Given('I have a subdirectory {string}') do |path|
  @subdirectory = File.join(@test_root, path)
  FileUtils.mkdir_p(@subdirectory)
end

Given('I have a subdirectory Attributes.ini with:') do |content|
  File.write(File.join(@subdirectory, 'Attributes.ini'), content)
end

When('I read the repository data') do
  reader = Attention::Reader.new(@test_root)
  @repo_data = reader.read_repo
end

Then('the subdirectory should inherit root attributes') do
  relative_path = Pathname.new(@subdirectory).relative_path_from(Pathname.new(@test_root)).to_s
  subdir_data = @repo_data[:attributes][relative_path]
  
  expect(subdir_data).to have_key('TechnicalDebt')
end

Then('the subdirectory should override {string} with {float}') do |attribute, value|
  relative_path = Pathname.new(@subdirectory).relative_path_from(Pathname.new(@test_root)).to_s
  subdir_data = @repo_data[:attributes][relative_path]
  
  expect(subdir_data['TechnicalDebt']['code_coverage']).to eq(value)
end

Given('I have multiple directories with INI files') do
  # Create root level
  File.write(File.join(@test_root, 'Attributes.ini'), "[TechnicalDebt]\ncode_coverage=0.5\n")
  
  # Create subdirectory
  subdir = File.join(@test_root, 'services')
  FileUtils.mkdir_p(subdir)
  File.write(File.join(subdir, 'Attributes.ini'), "[Operator]\nuptime=0.9\n")
end

When('I dump the repository to JSON') do
  dumper = Attention::Dumper.new(@test_root)
  @dump_result = dumper.dump_repo
end

Then('a file {string} should be created') do |filename|
  file_path = File.join(@test_root, filename)
  expect(File.exist?(file_path)).to be true
  @dump_file = file_path
end

When('I delete all INI files') do
  Dir.glob(File.join(@test_root, '**', '*.ini')).each do |file|
    File.delete(file)
  end
end

When('I apply the repository from JSON') do
  applier = Attention::Applier.new(@test_root)
  @apply_result = applier.apply_repo
end

Then('all INI files should be restored') do
  expect(@apply_result[:success]).to be true
  ini_files = Dir.glob(File.join(@test_root, '**', '*.ini'))
  expect(ini_files).not_to be_empty
end

Given('I have the following attributes:') do |table|
  table.hashes.each do |row|
    path = File.join(@test_root, row['Path'])
    FileUtils.mkdir_p(path)
    
    file_path = File.join(path, 'Attributes.ini')
    content = "[#{row['Facet']}]\n#{row['Attribute']}=#{row['Value']}\n"
    
    if File.exist?(file_path)
      File.write(file_path, File.read(file_path) + "\n" + content)
    else
      File.write(file_path, content)
    end
  end
end

Given('I have the following priorities:') do |table|
  table.hashes.each do |row|
    path = File.join(@test_root, row['Path'])
    FileUtils.mkdir_p(path)
    
    file_path = File.join(path, 'Priorities.ini')
    content = "[#{row['Facet']}]\n#{row['Attribute']}=#{row['Value']}\n"
    
    if File.exist?(file_path)
      File.write(file_path, File.read(file_path) + "\n" + content)
    else
      File.write(file_path, content)
    end
  end
end

When('I calculate urgency') do
  reader = Attention::Reader.new(@test_root)
  data = reader.read_repo
  
  calculator = Attention::Calculator.new(data[:attributes], data[:priorities])
  @urgency_results = calculator.calculate_urgency
end

Then('{string} should have the highest urgency') do |item_description|
  parts = item_description.split(' ')
  expect(@urgency_results.first[:path]).to include(parts[0])
  expect(@urgency_results.first[:facet]).to eq(parts[1])
  expect(@urgency_results.first[:attribute]).to eq(parts[2])
end

Then('the urgency should be {float}') do |expected_urgency|
  actual_urgency = @urgency_results.first[:urgency]
  expect(actual_urgency).to be_within(0.01).of(expected_urgency)
end

Given('I have a technical debt item with {int}% completion') do |completion|
  @initial_completion = completion / 100.0
  File.write(File.join(@test_root, 'Attributes.ini'), "[TechnicalDebt]\nrefactoring=#{@initial_completion}\n")
  File.write(File.join(@test_root, 'Priorities.ini'), "[TechnicalDebt]\nrefactoring=0.8\n")
  
  reporter = Attention::Reporter.new(@test_root)
  @initial_report = reporter.detailed_report
  @initial_urgency = @initial_report[:urgency_ranking].first[:urgency]
end

When('I update the completion to {int}%') do |new_completion|
  @new_completion = new_completion / 100.0
  File.write(File.join(@test_root, 'Attributes.ini'), "[TechnicalDebt]\nrefactoring=#{@new_completion}\n")
end

Then('the urgency should decrease') do
  expect(@detailed_report[:urgency_ranking].first[:urgency]).to be < @initial_urgency
end

Then('the completion percentage should show {int}%') do |expected_percent|
  actual_percent = @detailed_report[:urgency_ranking].first[:completion_percent]
  expect(actual_percent).to eq(expected_percent.to_f)
end
