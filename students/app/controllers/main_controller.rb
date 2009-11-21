require 'ostruct'

class MainController < ApplicationController
  layout "main", :except => :results
  
  def index
    @contests = Contest.current.select {|contest| contest.visible or current_user.andand.admin?}
    @practice_contests = Contest.practicable.select {|contest| contest.visible or current_user.andand.admin?}
    @top_scores = calc_rankings(:limit => 3)
  end
  
  def results
    @contest = Contest.find(params[:contest_id])
    if !(@contest.results_visible? or current_user.andand.admin?)
      redirect_to root_path
      return
    end
    
    students = @contest.runs.during_contest.map(&:user).uniq
    # Results are in the form:
    # [
    #   [student_name, [task1_test1_pts, task1_test2_pts], [task2_test1_pts, ...]]
    # ]
    @results = students.reject(&:admin?).map do |student|
      total = 0
      [student.name] + @contest.problems.map do |problem|
        last_run = problem.runs.during_contest.select { |r| r.user == student }.first
        
        if last_run
          total += last_run.total_points
          last_run.points + [last_run.total_points]
        else
          ["0"] * problem.number_of_tests + ["0"]
        end
      end + [total]
    end
    
    @results.sort! { |a,b| b[-1] <=> a[-1] }
    
    # Compute the unique scores and the number people with each score
    diff_scores = @results.map(&:last).uniq.map { |score| [score, @results.select { |res| res.last == score }.length] }
    @results.each do |row|
      row.unshift diff_scores.map { |score, number| score > row.last ? number : 0 }.sum + 1
    end
    render :action => :results, :layout => "results"
  end
  
  def rankings
    @rankings = calc_rankings
  end
  
  def download_tests
    Dir.chdir $config[:sets_root] do
      FileUtils.rm "sets.zip" if File.file?("sets.zip")
      Zip::ZipFile.open("sets.zip", Zip::ZipFile::CREATE) do |zipfile|
        Dir.glob("**/*") do |entry|
          zipfile.mkdir(entry) if File.directory?(entry)
          zipfile.add entry, entry if File.file?(entry)
        end
      end
    end

    send_file File.join($config[:sets_root], "sets.zip")
  end

  private
    def calc_rankings(options = {})
      rankings = User.generate_ranklist(options).map do |row|
        OpenStruct.new(
          :user => row[0],
          :total_points => row[1].to_i,
          :total_runs => row[2],
          :full_solutions => row[3])
      end
    end
end
