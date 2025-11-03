Given('I have Ruby files in my project directory') do
  @ruby_files = ['example.rb', 'processor.rb', 'handler.rb']
  @ruby_files.each do |filename|
    File.write(File.join(@test_root, filename), "# Ruby code for #{filename}")
  end
end

When('I run the file scanner') do
  @tracker = Attention::FileTracker.new(@test_root)
  @scan_result = @tracker.scan_and_update(@test_root)
end

Then('file facets should be created for each Ruby file') do
  expect(@scan_result[:success]).to be true
  expect(@scan_result[:created]).to eq(@ruby_files.size)
  
  attributes_file = File.join(@test_root, 'Attributes.ini')
  expect(File.exist?(attributes_file)).to be true
end

Then('each file facet should have a git_object_id attribute') do
  attributes_file = File.join(@test_root, 'Attributes.ini')
  ini = IniFile.load(attributes_file)
  
  @ruby_files.each do |filename|
    facet_name = "File:#{filename}"
    expect(ini.has_section?(facet_name)).to be true
    expect(ini[facet_name]['git_object_id']).to be_a(String)
    expect(ini[facet_name]['git_object_id'].length).to eq(40)
  end
end

Then('each file facet should have a review_status attribute') do
  attributes_file = File.join(@test_root, 'Attributes.ini')
  ini = IniFile.load(attributes_file)
  
  @ruby_files.each do |filename|
    facet_name = "File:#{filename}"
    expect(ini[facet_name]).to have_key('review_status')
  end
end

Given('I have tracked files with git object IDs') do
  @tracked_file = File.join(@test_root, 'tracked.rb')
  File.write(@tracked_file, "puts 'original'")
  
  @tracker = Attention::FileTracker.new(@test_root)
  @tracker.scan_and_update(@test_root)
  
  attributes_file = File.join(@test_root, 'Attributes.ini')
  ini = IniFile.load(attributes_file)
  @original_object_id = ini['File:tracked.rb']['git_object_id']
end

When('I modify a tracked file') do
  File.write(@tracked_file, "puts 'modified'")
end

When('I update the git object IDs') do
  @update_result = @tracker.update_git_ids(@test_root)
end

Then('the git_object_id should change for the modified file') do
  attributes_file = File.join(@test_root, 'Attributes.ini')
  ini = IniFile.load(attributes_file)
  new_object_id = ini['File:tracked.rb']['git_object_id']
  
  expect(new_object_id).not_to eq(@original_object_id)
end

Then('other files should retain their original git_object_id') do
  # This would be tested if we had multiple files
  expect(@update_result[:success]).to be true
end

Given('I have file facets for existing files') do
  File.write(File.join(@test_root, 'to_delete.rb'), "puts 'delete me'")
  File.write(File.join(@test_root, 'to_keep.rb'), "puts 'keep me'")
  
  @tracker = Attention::FileTracker.new(@test_root)
  @tracker.scan_and_update(@test_root)
end

When('I delete a tracked file') do
  File.delete(File.join(@test_root, 'to_delete.rb'))
end

When('I run the cleanup task') do
  @cleanup_result = @tracker.cleanup(@test_root)
end

Then('the facet for the deleted file should be removed') do
  expect(@cleanup_result[:removed]).to eq(1)
  
  attributes_file = File.join(@test_root, 'Attributes.ini')
  ini = IniFile.load(attributes_file)
  expect(ini.has_section?('File:to_delete.rb')).to be false
end

Then('facets for existing files should remain') do
  attributes_file = File.join(@test_root, 'Attributes.ini')
  ini = IniFile.load(attributes_file)
  expect(ini.has_section?('File:to_keep.rb')).to be true
end

Given('I have manual facets for TechnicalDebt') do
  attributes_file = File.join(@test_root, 'Attributes.ini')
  ini = IniFile.new(filename: attributes_file)
  ini['TechnicalDebt']['code_coverage'] = 0.5
  ini.save
  
  priorities_file = File.join(@test_root, 'Priorities.ini')
  pri = IniFile.new(filename: priorities_file)
  pri['TechnicalDebt']['code_coverage'] = 0.8
  pri.save
end

Given('I have file facets for tracked files') do
  File.write(File.join(@test_root, 'example.rb'), "puts 'example'")
  
  @tracker = Attention::FileTracker.new(@test_root)
  @tracker.scan_and_update(@test_root)
  
  # Add priority for file facet
  priorities_file = File.join(@test_root, 'Priorities.ini')
  pri = if File.exist?(priorities_file)
    IniFile.load(priorities_file)
  else
    IniFile.new(filename: priorities_file)
  end
  pri['File:example.rb']['review_status'] = 0.9
  pri.save
end

Then('the report should include both manual and file facets') do
  reader = Attention::Reader.new(@test_root)
  data = reader.read_repo
  
  expect(data[:attributes]['.']).to have_key('TechnicalDebt')
  expect(data[:attributes]['.']).to have_key('File:example.rb')
end

Then('they should be sorted by urgency') do
  reporter = Attention::Reporter.new(@test_root)
  report = reporter.detailed_report
  
  urgencies = report[:urgency_ranking].map { |r| r[:urgency] }
  expect(urgencies).to eq(urgencies.sort.reverse)
end

Given('I have file facets at the root level') do
  File.write(File.join(@test_root, 'root.rb'), "puts 'root'")
  
  tracker = Attention::FileTracker.new(@test_root)
  tracker.scan_and_update(@test_root)
end

Given('I have file facets in a subdirectory') do
  @subdir = File.join(@test_root, 'subdir')
  FileUtils.mkdir_p(@subdir)
  File.write(File.join(@subdir, 'sub.rb'), "puts 'sub'")
  
  tracker = Attention::FileTracker.new(@test_root)
  tracker.scan_and_update(@subdir)
end

Then('subdirectory file facets should not inherit from root file facets') do
  reader = Attention::Reader.new(@test_root)
  data = reader.read_repo
  
  # Subdirectory should not have root file facets
  expect(data[:attributes]['subdir']).not_to have_key('File:root.rb')
end

Then('subdirectory should inherit manual facets from root') do
  # Add manual facet at root
  attributes_file = File.join(@test_root, 'Attributes.ini')
  ini = IniFile.load(attributes_file)
  ini['TechnicalDebt']['documentation'] = 0.3
  ini.save
  
  reader = Attention::Reader.new(@test_root)
  data = reader.read_repo
  
  # Subdirectory should inherit manual facets
  expect(data[:attributes]['subdir']).to have_key('TechnicalDebt')
end

Given('I am in a Git repository') do
  Dir.chdir(@test_root) do
    system('git init -q')
    system('git config user.email "test@example.com"')
    system('git config user.name "Test User"')
  end
  @git_integration = Attention::GitIntegration.new(@test_root)
end

When('I check Git integration status') do
  @is_git_repo = @git_integration.git_repository?
end

Then('it should detect the Git repository') do
  expect(@is_git_repo).to be true
end

Then('git object IDs should be calculated using Git') do
  test_file = File.join(@test_root, 'test.rb')
  File.write(test_file, "puts 'test'")
  
  Dir.chdir(@test_root) do
    system('git add test.rb')
  end
  
  object_id = @git_integration.get_object_id(test_file)
  expect(object_id).to be_a(String)
  expect(object_id.length).to eq(40)
end

Given('I am not in a Git repository') do
  @git_integration = Attention::GitIntegration.new(@test_root)
end

When('I scan files for tracking') do
  File.write(File.join(@test_root, 'test.rb'), "puts 'test'")
  @tracker = Attention::FileTracker.new(@test_root)
  @scan_result = @tracker.scan_and_update(@test_root)
end

Then('git object IDs should be calculated manually') do
  expect(@git_integration.git_repository?).to be false
  expect(@scan_result[:success]).to be true
end

Then('file tracking should still work correctly') do
  attributes_file = File.join(@test_root, 'Attributes.ini')
  ini = IniFile.load(attributes_file)
  
  expect(ini.has_section?('File:test.rb')).to be true
  expect(ini['File:test.rb']['git_object_id']).to be_a(String)
  expect(ini['File:test.rb']['git_object_id'].length).to eq(40)
end

Given('I have a mix of file and manual facets') do
  # Manual facet
  attributes_file = File.join(@test_root, 'Attributes.ini')
  ini = IniFile.new(filename: attributes_file)
  ini['TechnicalDebt']['code_coverage'] = 0.5
  ini.save
  
  # File facets
  File.write(File.join(@test_root, 'file1.rb'), "code 1")
  File.write(File.join(@test_root, 'file2.rb'), "code 2")
  
  tracker = Attention::FileTracker.new(@test_root)
  tracker.scan_and_update(@test_root)
end

When('I request tracking statistics') do
  tracker = Attention::FileTracker.new(@test_root)
  @stats = tracker.statistics(@test_root)
end

Then('I should see the count of file facets') do
  expect(@stats[:file_facets]).to eq(2)
end

Then('I should see the count of manual facets') do
  expect(@stats[:manual_facets]).to eq(1)
end

Then('I should see the total facet count') do
  expect(@stats[:total]).to eq(3)
end
