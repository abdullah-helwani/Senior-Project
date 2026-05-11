<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

/**
 * Fixes parent/student names (guarantees uniqueness, no duplicates)
 * and rebuilds studentguardian so every parent has at least one real student child.
 *
 * 70 families total:
 *   - Families 0-25 (26): two children each  → 52 students
 *   - Families 26-69 (44): one child each    → 44 students
 *   Total students: 52 + 44 = 96 ✓
 *
 * Children share the family's last name with their parent.
 * All 166 names (70 parents + 96 students) are globally unique.
 */
class FixFamilyDataSeeder extends Seeder
{
    public function run(): void
    {
        // ── 70 unique family last names (one per family) ──────────────────────
        $lastNames = [
            'Al-Rashidi',  'Al-Qahtani',   'Al-Ghamdi',   'Al-Shehri',  'Al-Harbi',     // 0-4
            'Al-Mutairi',  'Al-Dossari',   'Al-Zahrani',  'Al-Ahmadi',  'Al-Anazi',      // 5-9
            'Al-Subaie',   'Al-Fahadi',    'Al-Mansouri', 'Al-Khalidi', 'Al-Hashimi',    // 10-14
            'Al-Hamdani',  'Al-Sulaimani', 'Al-Saudi',    'Al-Otaibi',  'Al-Rasheed',    // 15-19
            'Al-Khaldi',   'Al-Saleh',     'Al-Enezi',    'Al-Balawi',  'Al-Dawsari',    // 20-24
            'Al-Farsi',    'Al-Ghanim',    'Al-Hajri',    'Al-Jaber',   'Al-Kaabi',      // 25-29
            'Al-Malki',    'Al-Naimi',     'Al-Omari',    'Al-Ruwaili', 'Al-Tamimi',     // 30-34
            'Al-Yami',     'Al-Zaydi',     'Al-Asmari',   'Al-Shammari','Al-Juaid',      // 35-39
            'Al-Suwailim', 'Al-Bishi',     'Al-Thubaiti', 'Al-Qaisi',   'Al-Sabah',      // 40-44
            'Al-Mubarak',  'Al-Harthi',    'Al-Amri',     'Al-Nufaie',  'Al-Humaidan',   // 45-49
            'Al-Qurashi',  'Al-Aqeel',     'Al-Barrak',   'Al-Fawzan',  'Al-Khathlan',   // 50-54
            'Al-Wohaibi',  'Al-Shaddi',    'Al-Qasim',    'Al-Rubai',   'Al-Matrafi',    // 55-59
            'Al-Luhaydan', 'Al-Muammar',   'Al-Osaimi',   'Al-Rabiah',  'Al-Jadaan',     // 60-64
            'Al-Mulla',    'Al-Asiri',     'Al-Bogami',   'Al-Juhani',  'Al-Harthy',     // 65-69
        ];

        // Male first names — [0..34] for male parents, [35..82] for male students (48)
        $maleFN = [
            'Mohammed', 'Ibrahim',  'Ahmed',    'Khalid',   'Omar',      // 0-4
            'Abdullah', 'Faisal',   'Hassan',   'Tariq',    'Walid',     // 5-9
            'Yusuf',    'Salman',   'Nasser',   'Rami',     'Adel',      // 10-14
            'Bilal',    'Hamad',    'Saud',     'Bandar',   'Nawaf',     // 15-19
            'Marwan',   'Majid',    'Anas',     'Saif',     'Hamza',     // 20-24
            'Yazid',    'Talal',    'Othman',   'Jamal',    'Issam',     // 25-29
            'Nabil',    'Mazen',    'Ziad',     'Sami',     'Ali',       // 30-34 (parent pool ends)
            // ── students ──
            'Karim',    'Rashid',   'Faris',    'Raed',     'Wael',      // 35-39
            'Badr',     'Amr',      'Suleiman', 'Hazim',    'Luay',      // 40-44
            'Munir',    'Yasir',    'Zayd',     'Akram',    'Bassam',    // 45-49
            'Shadi',    'Dirar',    'Elias',    'Falah',    'Ghazi',     // 50-54
            'Haytham',  'Jaber',    'Khalil',   'Marzouq',  'Naim',      // 55-59
            'Ammar',    'Firas',    'Riad',     'Saad',     'Tawfiq',    // 60-64
            'Wissam',   'Imad',     'Nadim',    'Osama',    'Qusay',     // 65-69
            'Sameer',   'Taleb',    'Yahya',    'Zaki',     'Ayman',     // 70-74
            'Bader',    'Fahad',    'Ghassan',  'Hatim',    'Iyas',      // 75-79
            'Jihad',    'Khaldoun', 'Faiez',                             // 80-82
        ];

        // Female first names — [0..34] for female parents, [35..82] for female students (48)
        $femaleFN = [
            'Layla',    'Maryam',   'Fatima',   'Amal',     'Sara',      // 0-4
            'Hanan',    'Zainab',   'Reem',     'Hala',     'Nour',      // 5-9
            'Aisha',    'Yasmin',   'Zara',     'Shahad',   'Maha',      // 10-14
            'Lina',     'Rana',     'Latifa',   'Sumaya',   'Mona',      // 15-19
            'Rawan',    'Areej',    'Nawal',    'Bushra',   'Hessa',     // 20-24
            'Ghada',    'Asma',     'Tala',     'Dana',     'Hind',      // 25-29
            'Munira',   'Najla',    'Lujain',   'Aida',     'Dalal',     // 30-34 (parent pool ends)
            // ── students ──
            'Salma',    'Khadija',  'Widad',    'Abeer',    'Basma',     // 35-39
            'Bothaina', 'Dina',     'Eman',     'Faten',    'Ghadeer',   // 40-44
            'Haifa',    'Iman',     'Khawla',   'Lubna',    'Maissa',    // 45-49
            'Nadia',    'Rula',     'Safiya',   'Tahani',   'Wafaa',     // 50-54
            'Yara',     'Amira',    'Bayan',    'Dalia',    'Elham',     // 55-59
            'Fadwa',    'Hadeel',   'Intisar',  'Kawthar',  'Lama',      // 60-64
            'Marwa',    'Nada',     'Raghad',   'Suha',     'Waad',      // 65-69
            'Alaa',     'Batool',   'Shaimaa',  'Rim',      'Souad',     // 70-74
            'Thanaa',   'Wijdan',   'Roba',     'Zena',     'Abrar',     // 75-79
            'Bodour',   'Shatha',   'Galia',                             // 80-82
        ];

        // Parent emails in family order (family index = 0..69)
        $parentEmails = ['parent@school.test'];
        for ($i = 1; $i <= 69; $i++) {
            $parentEmails[] = "parent{$i}@school.test";
        }

        // Student emails in assignment order
        $studentEmails = ['ali@school.test', 'fatima@school.test'];
        for ($i = 2; $i <= 95; $i++) {
            $studentEmails[] = 'student' . str_pad((string) $i, 3, '0', STR_PAD_LEFT) . '@school.test';
        }

        // ── Build families ────────────────────────────────────────────────────
        $maleParentCursor    = 0;
        $femaleParentCursor  = 0;
        $maleStudentCursor   = 0; // used as maleFN[35 + cursor]
        $femaleStudentCursor = 0; // used as femaleFN[35 + cursor]
        $studentEmailIdx     = 0;

        $families = [];

        for ($fi = 0; $fi < 70; $fi++) {
            $lastName    = $lastNames[$fi];
            $parentEmail = $parentEmails[$fi];
            $isMaleParent = ($fi % 2 === 0);

            $parentName = $isMaleParent
                ? $maleFN[$maleParentCursor++]   . ' ' . $lastName
                : $femaleFN[$femaleParentCursor++] . ' ' . $lastName;

            // Families 0-25 get 2 children; families 26-69 get 1 child
            $childCount = ($fi < 26) ? 2 : 1;
            $children   = [];

            for ($ci = 0; $ci < $childCount; $ci++) {
                $studentEmail = $studentEmails[$studentEmailIdx++];

                if ($childCount === 2) {
                    // First child male, second female
                    $isMaleChild = ($ci === 0);
                } else {
                    // One-child families: alternate by family index
                    $isMaleChild = ($fi % 2 === 0);
                }

                $childName = $isMaleChild
                    ? $maleFN[35 + $maleStudentCursor++]    . ' ' . $lastName
                    : $femaleFN[35 + $femaleStudentCursor++] . ' ' . $lastName;

                $children[] = ['email' => $studentEmail, 'name' => $childName];
            }

            $families[] = [
                'parent_email' => $parentEmail,
                'parent_name'  => $parentName,
                'children'     => $children,
            ];
        }

        // ── 1. Update user names ──────────────────────────────────────────────
        $parentUpdated  = 0;
        $studentUpdated = 0;

        foreach ($families as $family) {
            $rows = DB::table('users')->where('email', $family['parent_email'])->update(['name' => $family['parent_name']]);
            $parentUpdated += $rows;

            foreach ($family['children'] as $child) {
                $rows = DB::table('users')->where('email', $child['email'])->update(['name' => $child['name']]);
                $studentUpdated += $rows;
            }
        }

        // ── 2. Rebuild studentguardian ────────────────────────────────────────
        DB::table('studentguardian')->delete();

        $linksInserted = 0;
        foreach ($families as $family) {
            $parentUserId = DB::table('users')->where('email', $family['parent_email'])->value('id');
            if (!$parentUserId) continue;

            $parentId = DB::table('parent')->where('user_id', $parentUserId)->value('parent_id');
            if (!$parentId) continue;

            foreach ($family['children'] as $child) {
                $studentUserId = DB::table('users')->where('email', $child['email'])->value('id');
                if (!$studentUserId) continue;

                $studentId = DB::table('students')->where('user_id', $studentUserId)->value('id');
                if (!$studentId) continue;

                DB::table('studentguardian')->insert([
                    'student_id'   => $studentId,
                    'parent_id'    => $parentId,
                    'relationship' => 'parent',
                    'isprimary'    => true,
                ]);
                $linksInserted++;
            }
        }

        $this->command->info('=== FixFamilyDataSeeder complete ===');
        $this->command->info("Parent names updated : {$parentUpdated}");
        $this->command->info("Student names updated: {$studentUpdated}");
        $this->command->info("Family links inserted: {$linksInserted} (70 parents, 96 students)");
        $this->command->info('26 parents have 2 children, 44 parents have 1 child');
    }
}
